#!/usr/bin/env python3

import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk
import threading
import cv2 as cv
import time
import numpy as np
import os

from CameraDelegate import CameraDelegate
import simplejpeg
import subprocess

cd = CameraDelegate('192.168.0.1', 61271)
cd.start_stream()

class CameraApp:
    def __init__(self, root):

        frame = np.zeros((720,1280))
        try:
            frame = cd.get_current_frame()
            frame = simplejpeg.decode_jpeg(frame,strict=False)
            frame = cv.cvtColor(frame, cv.COLOR_BGR2RGB)
        except:
            pass

        self.root = root
        self.root.title("LLaVA Interface")


        self.canvas = tk.Canvas(root, width=frame.shape[1], height=frame.shape[0])
        self.canvas.pack()

        # Right panel
        self.right_panel = tk.Frame(root, bg="gray", width=frame.shape[1], height=frame.shape[0])
        self.right_panel.pack(side=tk.RIGHT, fill=tk.Y)

        self.left_panel = tk.Frame(root, bg="gray", width=frame.shape[1], height=frame.shape[0])
        self.left_panel.pack(side=tk.LEFT, fill=tk.Y)

        # Image drop zone
        self.image_label = tk.Label(self.right_panel, text="Drop Image Here", bg="lightgray", padx=10, pady=10)
        self.image_label.pack(pady=10, expand=True)
        self.image_label.bind("<Button-1>", self.load_image)


        self.image_label2 = tk.Label(self.left_panel, text="Drone Image Preview", bg="lightgray", padx=10, pady=10)
        self.image_label2.pack(pady=10, expand=True)

        # "Send to Model" button
        self.send_button = tk.Button(self.right_panel, text="Send to Model", command=self.send_to_model)
        self.send_button.pack(pady=10)

        self.file_path_object_to_search = ""
        self.current_frame = None
        self.scene_img = f"{os.getcwd()}/current_scene.jpg"
        

    def load_image(self, event):

        # save current frame as an image
        self.current_frame = cv.cvtColor(self.current_frame, cv.COLOR_BGR2RGB)
        cv.imwrite('current_scene.jpg', self.current_frame)

        # find image to select
        file_path = filedialog.askopenfilename()
        if file_path:
            self.file_path_object_to_search = file_path
            img = Image.open(file_path)
            img.thumbnail((150, 150))
            img = ImageTk.PhotoImage(img)
            self.image_label.config(image=img)
            self.image_label.image = img 


            img2 = Image.open(self.scene_img)
            img2.thumbnail((150, 150))
            img2 = ImageTk.PhotoImage(img2)
            self.image_label2.config(image=img2)
            self.image_label2.image = img2 

    def send_to_model(self):
        loading_window = tk.Toplevel(self.root)
        loading_label = tk.Label(loading_window, text="Loading response: Calling LLaVa...", font=("Helvetica", 16))
        loading_label.pack(padx=20, pady=20)
        loading_window.update()
        
        # Replace this with the actual result from your function
        result_text1, result_text2, p1, p2 = self.call_up_llava()

        loading_window.destroy()

        # Show result in a new window
        result_window = tk.Toplevel(self.root)

        q_label = tk.Label(result_window, text=f"Q: {p1}", font=("Helvetica", 16), fg="red")
        a_label = tk.Label(result_window, text=f"A: {result_text1}", font=("Helvetica", 16))
        q2_label = tk.Label(result_window, text=f"Q: {p2}", font=("Helvetica", 16), fg="red")
        a2_label = tk.Label(result_window, text=f"A: {result_text2}", font=("Helvetica", 16))

        # Pack the labels
        q_label.pack(padx=20, pady=10)
        a_label.pack(padx=20, pady=10)

        q2_label.pack(padx=20, pady=10)
        a2_label.pack(padx=20, pady=10)


    def call_up_llava(self):

        llava_prompt = "Tell me only the main object that you see. Do not provide a sentence."

        print(f'Searching: {self.file_path_object_to_search}')
        object_to_find_image = self.file_path_object_to_search
        output = subprocess.run(["./llava-cli", "-m", "ggml-model-q5_k.gguf", "--mmproj", "mmproj-model-f16.gguf", "--image", f"{object_to_find_image}", "--prompt", f"\"{llava_prompt}\""], capture_output=True)
        decoded = output.stdout.decode('UTF-8')
        
        print(f'With {self.scene_img}')
        llava_prompt_2 = f"Is there a {decoded.rstrip()} anywhere here? Yes or no."
        scene_image = self.scene_img
        output2 = subprocess.run(["./llava-cli", "-m", "ggml-model-q5_k.gguf", "--mmproj", "mmproj-model-f16.gguf", "--image", f"{scene_image}", "--prompt", f"\"{llava_prompt_2}\""], capture_output=True)
        decoded2 = output2.stdout.decode('UTF-8')

        return decoded, decoded2, llava_prompt, llava_prompt_2


    def update_camera(self):
        while True:
            frame = None
            try:
                frame = cd.get_current_frame()
            except:
                pass

            if frame is not None:
                frame = simplejpeg.decode_jpeg(frame,strict=False)
                self.current_frame = frame
                photo = ImageTk.PhotoImage(image=Image.fromarray(frame))
                self.canvas.create_image(0, 0, image = photo, anchor = tk.NW)
            else:
                photo = ImageTk.PhotoImage(image=Image.fromarray(np.zeros(1920,1080)))
                self.canvas.create_image(0, 0, image = photo, anchor = tk.NW)
            self.root.update()  # Schedule the next update



if __name__ == "__main__":
    root = tk.Tk()
    app = CameraApp(root)
    app.update_camera()