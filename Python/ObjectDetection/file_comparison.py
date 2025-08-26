import csv

def metrics_calculation(b1, b2):
    intersection = intersection_calc(b1, b2)
    union = union_calc(intersection, b1, b2)

    percent_overlap = intersection / (b2['w']*b2['h'])
    iou = intersection / union

    return percent_overlap, iou

def intersection_calc(b1, b2):
    dx = max(min(b1['x'] + b1['w'], b2['x'] + b2['w']) - max(b1['x'], b2['x']), 0)
    dy = max(min(b1['y'] + b1['h'], b2['y'] + b2['h']) - max(b1['y'], b2['y']), 0)

    return dx*dy

def union_calc(intersection, b1, b2):
    b1_area =  b1['w']*b1['h']
    b2_area = b2['w']*b2['h']

    return (b1_area + b2_area) - intersection

DETECTION_NS_CSV = ""
DETECTION_S_CSV = ""
LABEL_CSV = ""
FINAL_NUMBERS_TEXT = ""
MATCH_VALUE = 0
FRAMES = 20

TIME_PER_FRAME = 50000
SECONDS_IN_VIDEO = 153


for frame in range(1, FRAMES+1):
    detection_ns_dict = {}
    detection_s_dict = {}
    label_dict = {}
    with open(DETECTION_NS_CSV, 'r') as f:
        detect_ns_reader = csv.reader(f, delimiter=' ')

        for idx, row in enumerate(detect_ns_reader):
            if float(row[3]) < 0:
                row[3] = '0'

            if float(row[4]) < 0:
                row[4] = '0'

            for i in range(len(row)):
                row[i] = int(round(float(row[i])))

            detection_ns_dict[idx] = row

    with open(DETECTION_S_CSV, 'r') as f:
        detect_s_reader = csv.reader(f, delimiter=' ')

        for idx, row in enumerate(detect_s_reader):
            if float(row[1]) < 0:
                row[3] = '0'

            if float(row[2]) < 0:
                row[4] = '0'

            for i in range(len(row)):
                row[i] = int(round(float(row[i])))

            detection_s_dict[idx] = row


    with open(LABEL_CSV, 'r') as f:
        label_reader = csv.reader(f, delimiter=' ')

        for idx, row in enumerate(label_reader):
            if float(row[1]) < 0:
                row[3] = '0'

            if float(row[2]) < 0:
                row[4] = '0'

            for i in range(len(row)):
                row[i] = int(round(float(row[i])))

            row.append(False)
            row.append(False)

            label_dict[idx] = row

    running_percentage_s = 0
    running_iou_s = 0
    running_percentage_ns = 0
    running_iou_ns = 0
    true_positive_s = 0
    detection_found_s = 0
    false_positive_s = 0
    true_positive_ns = 0
    detection_found_ns = 0
    false_positive_ns = 0

    for second in range(SECONDS_IN_VIDEO + 1):
        detections_ns = []
        detections_s = []
        labels = []
        for box in detection_ns_dict:
            ts = detection_ns_dict[box][0]
            if ts >= second*1000000 - frame*TIME_PER_FRAME and ts < second*1000000 + frame*TIME_PER_FRAME:
                detections_ns.append(box)

        for box in detection_s_dict:
            ts = detection_s_dict[box][0]
            if ts >= second*1000000 - frame*TIME_PER_FRAME and ts < second*1000000 + frame*TIME_PER_FRAME:
                detections_s.append(box)

        for label in label_dict:
            ts = label_dict[label][0]
            if ts >= second*1000000 - frame*TIME_PER_FRAME and ts < second*1000000 + frame*TIME_PER_FRAME:
                labels.append(label)

        for box in detections_ns:
            d_ts = detection_ns_dict[box][0]
            d_x = detection_ns_dict[box][3]
            d_y = detection_ns_dict[box][4]
            d_w = detection_ns_dict[box][5]
            d_h = detection_ns_dict[box][6]

            valid = False

            for label in labels:
                l_ts = label_dict[label][0]
                l_x = label_dict[label][1]
                l_y = label_dict[label][2]
                l_w = label_dict[label][3]
                l_h = label_dict[label][4]

                percent_overshoot, iou = metrics_calculation({'x': d_x, 'y': d_y, 'w': d_w, 'h':d_h}, {'x': l_x, 'y': l_y, 'w': l_w, 'h': l_h})

                if iou > MATCH_VALUE:
                    valid = True
                    if not label_dict[label][5]:
                        label_dict[label][5] = True
                        true_positive_ns += 1
                        running_percentage_ns += percent_overshoot
                        running_iou_ns += iou
                    break

            if not valid:
                false_positive_ns += 1/frame
                #if frame == FRAMES:
                 #   print(detection_ns_dict[box])


        for box in detections_s:
            d_ts = detection_s_dict[box][0]
            d_x = detection_s_dict[box][3]
            d_y = detection_s_dict[box][4]
            d_w = detection_s_dict[box][5]
            d_h = detection_s_dict[box][6]

            valid = False

            for label in labels:
                l_ts = label_dict[label][0]
                l_x = label_dict[label][1]
                l_y = label_dict[label][2]
                l_w = label_dict[label][3]
                l_h = label_dict[label][4]

                percent_overshoot, iou = metrics_calculation({'x': d_x, 'y': d_y, 'w': d_w, 'h':d_h}, {'x': l_x, 'y': l_y, 'w': l_w, 'h': l_h})

                if iou > MATCH_VALUE:
                    valid = True
                    if not label_dict[label][6]:
                        label_dict[label][6] = True
                        true_positive_s += 1
                        running_percentage_s += percent_overshoot
                        running_iou_s += iou
                    break

            if not valid:
                false_positive_s += 1/frame


    avg_percent_ns = running_percentage_ns/(true_positive_ns + false_positive_ns)
    avg_iou_ns = running_iou_ns/(true_positive_ns + false_positive_ns)
    precision_ns = true_positive_ns/(true_positive_ns + false_positive_ns)
    recall_ns = true_positive_ns/len(label_dict.keys())

    avg_percent_s = running_percentage_s/(true_positive_s + false_positive_s)
    avg_iou_s = running_iou_s/(true_positive_s + false_positive_s)
    precision_s = true_positive_s/(true_positive_s + false_positive_s)
    recall_s = true_positive_s/len(label_dict.keys())


    with open(FINAL_NUMBERS_TEXT, 'a') as f:
        f.write('----------' + str(frame) + '----------\n')
        f.write('NO SNOW \n')
        f.writelines('Avg Percent Overlap: ' + str(avg_percent_ns*100) + '%\n')
        f.writelines('Avg IOU: ' + str(avg_iou_ns*100) + '%\n')
        f.writelines('Precision: ' + str(precision_ns) + '\n')
        f.writelines('Recall: ' + str(recall_ns) + '\n')
        f.writelines('Number of cars found: ' + str(true_positive_ns) + '/' + str(len(label_dict.keys())) + '\n')
        f.writelines('Number of misfires: ' + str(false_positive_ns) + '\n\n')

        f.write('SNOW \n')
        f.writelines('Avg Percent Overlap: ' + str(avg_percent_s*100) + '%\n')
        f.writelines('Avg IOU: ' + str(avg_iou_s*100) + '%\n')
        f.writelines('Precision: ' + str(precision_s) + '\n')
        f.writelines('Recall: ' + str(recall_s) + '\n')
        f.writelines('Number of cars found: ' + str(true_positive_s) + '/' + str(len(label_dict.keys())) + '\n')
        f.writelines('Number of misfires: ' + str(false_positive_s) + '\n\n')
        f.write('\n')
