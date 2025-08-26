import csv
import cv2

from os import listdir
from os.path import isfile

DETECTION_CSV_SNOW = ""
DETECTION_CSV_NOSNOW = ""
IMG_DIRECTORY = ""
SAVE_DIRECTORY = ""
LABEL_CSV = ""

detection_snow_dict = {}
detection_nosnow_dict = {}
label_dict = {}
imgs = []
lbl_list = []
prev_ts = 0

imgs = listdir(IMG_DIRECTORY)


with open(DETECTION_CSV_SNOW, 'r') as f:
    detect_reader = csv.reader(f, delimiter=' ')

    for idx, row in enumerate(detect_reader):
        if float(row[3]) < 0:
            row[3] = '0'

        if float(row[4]) < 0:
            row[4] = '0'

        for i in range(len(row)):
            row[i] = int(round(float(row[i])))

        detection_snow_dict[idx] = row


with open(DETECTION_CSV_NOSNOW, 'r') as f:
    detect_reader = csv.reader(f, delimiter=' ')

    for idx, row in enumerate(detect_reader):
        if float(row[3]) < 0:
            row[3] = '0'

        if float(row[4]) < 0:
            row[4] = '0'

        for i in range(len(row)):
            row[i] = int(round(float(row[i])))

        detection_nosnow_dict[idx] = row

print("======================LABELS=====================")
with open(LABEL_CSV, 'r') as f:
    label_reader = csv.reader(f, delimiter=' ')

    for idx, row in enumerate(label_reader):
        if float(row[1]) < 0:
            row[3] = '0'

        if float(row[2]) < 0:
            row[4] = '0'

        for i in range(len(row)):
            row[i] = int(round(float(row[i])))

        label_dict[idx] = row


for idx in range(len(label_dict.keys())):
    ts = label_dict[idx][0]
    lbl_list.append(label_dict[idx])

    if idx + 1 < len(label_dict.keys()):
        if label_dict[idx+1][0] == ts:
            continue

    for img in imgs:
        if '_' + str(ts) in img:
            print(img)
            print(ts)
            img_f = cv2.imread(IMG_DIRECTORY + '\\' + img)

            for lbl in lbl_list:
                cv2.rectangle(img_f, (lbl[1], lbl[2]), (lbl[1] + lbl[3], lbl[2] + lbl[4]), (255, 0, 0), 2)

            break


    lbl_list = []
    cv2.imwrite(SAVE_DIRECTORY + '\\' + img, img_f)
print("======================SNOW=====================")

for idx in range(len(detection_snow_dict.keys())):
    ts = detection_snow_dict[idx][0]
    lbl_list.append(detection_snow_dict[idx])

    if idx + 1 < len(detection_snow_dict.keys()):
        if detection_snow_dict[idx+1][0] == ts:
            continue

    for img in imgs:
        if '_' + str(ts - 50000) in img or '_' + str(ts - 50000) in img:
            print(img)
            print(ts)

            if isfile(SAVE_DIRECTORY + '\\' + img):
                img_f = cv2.imread(SAVE_DIRECTORY + '\\' + img)
            else:
                img_f = cv2.imread(IMG_DIRECTORY + '\\' + img)

            for lbl in lbl_list:
                for det in detection_snow_dict:
                    if ts - 50000 <= detection_snow_dict[det][0] and ts + 50000 >= detection_snow_dict[det][0]:
                        cv2.rectangle(img_f, (detection_snow_dict[det][3], detection_snow_dict[det][4]), (detection_snow_dict[det][3] + detection_snow_dict[det][5], detection_snow_dict[det][4] + detection_snow_dict[det][6]), (0, 255, 0), 2)

            break


    lbl_list = []
    cv2.imwrite(SAVE_DIRECTORY + '\\' + img, img_f)
print("======================NO SNOW=====================")

for idx in range(len(detection_nosnow_dict.keys())):
    ts = detection_nosnow_dict[idx][0]
    lbl_list.append(detection_nosnow_dict[idx])

    if idx + 1 < len(detection_nosnow_dict.keys()):
        if detection_nosnow_dict[idx+1][0] == ts:
            continue

    for img in imgs:
        if '_' + str(ts - 50000) in img or '_' + str(ts - 50000) in img:
            print(img)
            print(ts)

            if isfile(SAVE_DIRECTORY + '\\' + img):
                img_f = cv2.imread(SAVE_DIRECTORY + '\\' + img)
            else:
                img_f = cv2.imread(IMG_DIRECTORY + '\\' + img)

            for lbl in lbl_list:
                for det in detection_nosnow_dict:
                    if ts - 50000 <= detection_nosnow_dict[det][0] and ts + 50000 >= detection_nosnow_dict[det][0]:
                        cv2.rectangle(img_f, (detection_nosnow_dict[det][3], detection_nosnow_dict[det][4]), (detection_nosnow_dict[det][3] + detection_nosnow_dict[det][5], detection_nosnow_dict[det][4] + detection_nosnow_dict[det][6]), (0, 0, 255), 2)

            break


    lbl_list = []
    cv2.imwrite(SAVE_DIRECTORY + '\\' + img, img_f)


saved_imgs =  listdir(SAVE_DIRECTORY)
for img in saved_imgs:
    img_f = cv2.imread(SAVE_DIRECTORY + '\\' + img)

    cv2.imshow('image', img_f)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
