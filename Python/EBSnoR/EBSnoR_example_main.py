import argparse
import numpy as np
from metavision_sdk_core import OnDemandFrameGenerationAlgorithm
from metavision_sdk_ui import (
    EventLoop,
    BaseWindow,
    Window,
    UIAction,
    UIKeyEvent
)
from metavision_core.event_io import EventsIterator
from EBSnoR_processor import EBSnoRProcessor


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Process an event file using EBSnoR.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('filename', type=str, help="Name of file to process")
    parser.add_argument(
        '-t', '--threshold',
        type=int,
        default=10000,
        help="EBSnoR time threshold in microseconds."
    )
    parser.add_argument(
        '-w', '--window',
        type=int,
        default=0,
        help='EBSnoR spatial window in pixels.'
    )
    parser.add_argument(
        '-d', '--camera-dims',
        nargs=2,
        type=int,
        default=[1280, 720]
    )
    parser.add_argument(
        '--adaptive-window',
        action='store_true',
        help='Use EBSnoR adaptive spatial windowing method?'
    )
    args = parser.parse_args()
    cam_width, cam_height = args.camera_dims
    ev_iter = EventsIterator(args.filename, delta_t=33333, relative_timestamps=False)
    processor = EBSnoRProcessor(
        args.threshold,
        args.window,
        camera_dimensions=(cam_width, cam_height)
    )

    with Window(
        title="EBSnoR example",
        width=cam_width,
        height=cam_height, mode=BaseWindow.RenderMode.BGR
    ) as viewer:
        def keyboard_cb(key, scancode, action, mods):
            if action != UIAction.RELEASE:
                return
            if key == UIKeyEvent.KEY_ESCAPE or key == UIKeyEvent.KEY_Q:
                viewer.set_close_flag()

        viewer.set_keyboard_callback(keyboard_cb)

        event_frame_gen = OnDemandFrameGenerationAlgorithm(cam_width, cam_height)
        def on_cd_frame_cb(ts, cd_frame):
            viewer.show(cd_frame)

        event_frame_gen.set_output_callback(on_cd_frame_cb)

        for ev in ev_iter:
            processed_ev = processor.process(ev, adaptive_win=args.adaptive_window)
            event_frame_gen.process_events(processed_ev)

            if viewer.should_close():
                break
