% Clear everything i.e. memory, console, etc. and close all opened images
clear; clc; close all;

% Input folder
inputSet = './input/';

% Input image pairs for creating a Hybrid image
HybridImage([inputSet,'RichardDawkins.jpg'], [inputSet,'EmmaWatson.jpg']);
HybridImage([inputSet,'Assange.jpg'], [inputSet,'Fawkes.jpg']);
HybridImage([inputSet,'Sad.jpg'], [inputSet,'Surprise.jpg']);
HybridImage([inputSet,'Whitehouse.jpg'], [inputSet,'Sproul.jpg']);
HybridImage([inputSet,'Lion.jpg'], [inputSet,'LakerGirl.jpg']);

