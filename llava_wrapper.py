#!/usr/bin/env python3

import os
import sys
import subprocess
import time

IMG_DIR = f"{os.getcwd()}/ObjSimilarity/"


def begin():

	directories = os.listdir(IMG_DIR)
	directories.sort()


	llava_prompt = "Tell me only the object that you see."

	latencies = []

	for directory in directories:

		final = []

		images = os.listdir(f'{IMG_DIR}{directory}')
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

		latencies.append((llava_end - llava_start) + (llava_end2 - llava_start2))
		decoded2 = output2.stdout.decode('UTF-8')
		final.append(decoded2)

		print(f"Answer to prompt 1 ({llava_prompt}) {final[0]}\nAnswer to prompt 2 ({llava_prompt_2}) {final[1]}\n")
		print(f'Time to answer: {latencies[-1]}')
		print('\n')
		print('-'*50)

	print(f'Average turnaround time: {sum(latencies)/len(latencies):0.4f}s')

if __name__ == "__main__":
	begin()