import os
import cv2
import numpy as np
import torch
import metavision_sdk_ml
import metavision_sdk_cv
from skvideo.io import FFmpegWriter
from metavision_sdk_ml import EventBbox
from metavision_core.event_io import EventsIterator
from metavision_ml.detection_tracking import ObjectDetector
from metavision_ml.detection_tracking import draw_detections_and_tracklets
from metavision_sdk_core import BaseFrameGenerationAlgorithm
from csv import writer


class DetectionCNN():
    def __init__(self, cam_dim=(1280, 720), cnn_type='hist', output_vid=None, csv=None):
        (self.ev_width, self.ev_height) = cam_dim
        self.OUTPUT_VIDEO = output_vid

        if cnn_type == 'cube':
            self.NN_MODEL_DIRECTORY = os.path.abspath(os.path.join(os.getcwd(), "models", "red_event_cube_05_2020"))
        else:
            self.NN_MODEL_DIRECTORY = os.path.abspath(os.path.join(os.getcwd(), "models", "red_histogram_05_2020"))

        self.DEVICE = "cpu" # 'cpu', 'cude' (or 'cuda:0','cuda:1', etc)
        if torch.cuda.is_available():
            self.DEVICE = "cuda"

        self.NN_DOWNSCALE_FACTOR = 2
        self.DETECTOR_SCORE_THRESHOLD = 0.4
        self.NMS_IOU_THRESHOLD = 0.4

        self.network_input_width = torch.div(self.ev_width, self.NN_DOWNSCALE_FACTOR, rounding_mode='floor')
        self.network_input_height = torch.div(self.ev_height, self.NN_DOWNSCALE_FACTOR, rounding_mode='floor')

        self.object_detector, self.cdproc, self.frame_buffer = self.__setup_detectors()

        self.NN_accumulation_time = self.object_detector.get_accumulation_time()

        self.VIDEO_WRITER = self.__init_output()

        self.data_assoc = metavision_sdk_ml.DataAssociation(width=self.ev_width, height=self.ev_height, max_iou_inter_track=0.3)
        self.data_assoc_buffer = self.data_assoc.get_empty_output_buffer()

        if csv:
            self.csv = open(csv, 'w', newline='')
            self.csv_writer = writer(self.csv, delimiter=' ')
        else:
            self.csv = None
            self.csv_writer = None

    def __setup_detectors(self):
        object_detector = ObjectDetector(self.NN_MODEL_DIRECTORY,
                                         events_input_width=self.ev_width,
                                         events_input_height=self.ev_height,
                                         runtime=self.DEVICE,
                                         network_input_width=self.network_input_width,
                                         network_input_height=self.network_input_height,
                                        )
        object_detector.set_detection_threshold(self.DETECTOR_SCORE_THRESHOLD)
        object_detector.set_iou_threshold(self.NMS_IOU_THRESHOLD)

        cdproc = object_detector.get_cd_processor()
        frame_buffer = cdproc.init_output_tensor()

        if 'red_event_cube' in self.NN_MODEL_DIRECTORY:
            assert frame_buffer.shape == (10, self.network_input_height, self.network_input_width)
        else:
            assert frame_buffer.shape == (2, self.network_input_height, self.network_input_width)
        assert (frame_buffer == 0).all()

        return object_detector, cdproc, frame_buffer

    def __init_output(self):
        if self.OUTPUT_VIDEO:
            assert self.OUTPUT_VIDEO.lower().endswith(".mp4"), "Video should be mp4"
        cv2.namedWindow("Detection and Tracking", cv2.WINDOW_NORMAL)

        return FFmpegWriter(self.OUTPUT_VIDEO) if self.OUTPUT_VIDEO else None

    def __generate_detections(self, ts, ev):
        current_frame_start_ts = (torch.div((ts - 1), self.NN_accumulation_time, rounding_mode='floor')) * self.NN_accumulation_time
        self.cdproc.process_events(current_frame_start_ts, ev, self.frame_buffer)

        detections = np.empty(0, dtype=EventBbox)

        if ts % self.NN_accumulation_time == 0:
            detections = self.object_detector.process(ts, self.frame_buffer)
            self.frame_buffer.fill(0)

        self.data_assoc.process_events(ts, ev, detections, self.data_assoc_buffer)
        tracklets = self.data_assoc_buffer.numpy()

        return detections, tracklets

    def __generate_display(self, ts, ev, detections, tracklets):
        frame = np.zeros((self.ev_height, self.ev_width*2, 3), dtype=np.uint8)
        BaseFrameGenerationAlgorithm.generate_frame(ev, frame[:,:self.ev_width])
        frame[:,:self.ev_width] = frame[:,:self.ev_width]
        draw_detections_and_tracklets(ts=ts, frame=frame, width=self.ev_width, height=self.ev_height, detections=detections, tracklets=tracklets)

        cv2.imshow('Detection and Tracking', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            return False

        if self.OUTPUT_VIDEO:
            self.VIDEO_WRITER.writeFrame(frame[...,::-1].astype(np.uint8))
        return True


    def __write_csv(self, box):
        ts = box[0]
        x = box[1]
        y = box[2]
        w = box[3]
        h = box[4]
        class_id = box[5]
        track_id = box[6]
        class_confidence = box[7]

        csv_line = (ts, class_id, track_id, x, y, w, h, class_confidence)

        self.csv_writer.writerow(csv_line)

    def end_display(self):
        if self.OUTPUT_VIDEO:
            self.VIDEO_WRITER.close()
        cv2.destroyAllWindows()
        self.csv.close()

    def run_cnn(self, ev, ts):
        detections, tracklets = self.__generate_detections(ts, ev)
        if self.csv:
            for box in detections:
                self.__write_csv(box)

        #if not self.__generate_display(ts, ev, detections, tracklets):
          #  return True

        return False
