import cv2
import pyautogui
import numpy as np
import json
import time
import os

CONFIG_FILE = "ara_bara_bot_command.json"
OUTPUT_FILE = "ara_bara_bot_output.json"

def capture_screen():
    screenshot = pyautogui.screenshot()
    return np.array(screenshot)

def find_players():
    # OpenCV detection
    screen = capture_screen()
    # Пример: поиск красных объектов (врагов)
    lower_red = np.array([0, 0, 100])
    upper_red = np.array([100, 100, 255])
    mask = cv2.inRange(screen, lower_red, upper_red)
    contours, _ = cv2.findContours(mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    return len(contours)

def main():
    print("Python bot started")
    while True:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'r') as f:
                data = json.load(f)
            command = data.get('command', '')
            
            if command == 'scan_players':
                count = find_players()
                with open(OUTPUT_FILE, 'w') as f:
                    json.dump({'players': count}, f)
            elif command == 'click':
                pyautogui.click()
            elif command == 'move':
                x, y = data.get('x', 0), data.get('y', 0)
                pyautogui.moveTo(x, y)
            elif command == 'exit':
                break
            
            os.remove(CONFIG_FILE)
        time.sleep(0.1)

if __name__ == "__main__":
    main()