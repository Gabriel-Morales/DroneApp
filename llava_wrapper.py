#!/usr/bin/env python3

import os
import sys
import subprocess
import time

IMG_DIR = f"{os.getcwd()}/ObjSimilarity/"


Ground_truth = ['No','Yes','Yes','Yes', 'Yes', 'Yes', 'Yes', 
				'Yes', 'No', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes', 'Yes',
				'Yes', 'Yes', 'No', 'Yes'
				]
proper_objects = ['Remote','Computer','Bottle','Harry Potter Books', 'iPhone', 'Incense Sticks', 'Tassle',
				'Crayons', 'Slide', 'Piano', 'Bike', 'Hammer', 'Microscope', 'Keyboard', 'Christmas Tree', 'Trash Can',
				'Guitar', 'Mouse', 'Mattress', 'Hourglass'
				]

def begin():

	directories = os.listdir(IMG_DIR)
	directories = sorted(directories, key=lambda x: int(x))
	print(directories)

	llava_prompt = "Tell me only the main object that you see. Do not provide a sentence."

	latencies = []
	idx = 0
	for directory in directories:

		final = []

		images = os.listdir(f'{IMG_DIR}{directory}')
		print(f'[Directory #{directory}]')
		scene_image = ""
		object_to_find_image = ""

		if 'object' in images[0]:
			object_to_find_image = images[0]
			scene_image = images[1]
		else:
			object_to_find_image = images[1]
			scene_image = images[0]


		object_to_find_image = IMG_DIR + directory + os.path.sep + object_to_find_image
		scene_image = IMG_DIR + directory + os.path.sep + scene_image
		# invocation: ./llava-cli -m ggml-model-q5_k.gguf --mmproj mmproj-model-f16.gguf --image ../room.jpg --log-disable 2>/dev/null
		llava_start = time.perf_counter()
		output = subprocess.run(["./llava-cli", "-m", "ggml-model-q5_k.gguf", "--mmproj", "mmproj-model-f16.gguf", "--image", f"{object_to_find_image}", "--prompt", f"\"{llava_prompt}\""], capture_output=True)
		llava_end = time.perf_counter()
		decoded = output.stdout.decode('UTF-8')
		final.append(decoded)

		llava_prompt_2 = f"Is there a {decoded.rstrip()} anywhere here? Yes or no."
		llava_start2 = time.perf_counter()
		output2 = subprocess.run(["./llava-cli", "-m", "ggml-model-q5_k.gguf", "--mmproj", "mmproj-model-f16.gguf", "--image", f"{scene_image}", "--prompt", f"\"{llava_prompt_2}\""], capture_output=True)
		llava_end2 = time.perf_counter()

		timing = (llava_end - llava_start) + (llava_end2 - llava_start2)
		latencies.append(timing)
		decoded2 = output2.stdout.decode('UTF-8')
		final.append(decoded2)

		print(f"Answer to prompt 1 ({llava_prompt}) {final[0]}\nAnswer to prompt 2 ({llava_prompt_2}) {final[1]}\n")
		print(f'[Img for prompt 1: {object_to_find_image}]')
		print(f'[Img for prompt 2: {scene_image}]')
		print(f'[Proper Image Label: {proper_objects[idx]}]')
		print(f'[Is this object in the scene (ground truth): {Ground_truth[idx]}]')
		print(f'[Turnaround for scene: {timing:.4f}s]')
		print('-'*50)
		idx += 1

	print(f'Average turnaround time: {sum(latencies)/len(latencies):0.4f}s')

if __name__ == "__main__":
	begin()