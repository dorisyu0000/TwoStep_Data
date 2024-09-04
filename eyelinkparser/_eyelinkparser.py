# -*- coding: utf-8 -*-

import re
import numpy as np
import pandas as pd
import math
import json 

class EyeLinkParser:
    def __init__(self, eye_folder, asc_encoding='ISO-8859-1'):
        self.eye_dirfolder = eye_folder
        # self.trial_dir = trial_dir
        self.asc_encoding = asc_encoding
        self.current_offset = np.nan
        self.rows = []  # Collect all rows in a list to append at once
        self.trial_index = 0
        self.switch = 0
        self.visit = 0
        self.event = None
        # self.wid = wid
        self.node_positions = [
        [960.0, 162.0],
        [755.6377710017841, 222.00616458981358],
        [616.159105755992, 382.97312508528694],
        [585.8474949690074, 593.7950088673017],
        [674.3266608940903, 787.5373574313177],
        [853.5050935139395, 902.68834402628],
        [1066.4949064860602, 902.68834402628],
        [1245.6733391059095, 787.537357431318],
        [1334.1525050309926, 593.7950088673018],
        [1303.840894244008, 382.97312508528705],
        [1164.3622289982159, 222.00616458981352]
        ]
    
    def import_trial_data(self, trial_dir):
        """ Imports trial data from a JSON file. """
        with open(trial_dir, 'r') as file:
            return json.load(file)

    def parse_asc_file(self, path):
        """ Parses the ASC file for eye-tracking data. """
        with open(path, 'r', encoding=self.asc_encoding) as file:
            for line in file:
                if 'MSG' in line:
                    self.parse_message(line)
                if 'EFIX' in line:
                    self.parse_fixation(line)
                if re.match(r"^\d+\s+\d+\.\d+\s+\d+\.\d+", line):
                    self.parse_gaze(line)
                if 'EBLINK' in line:
                    self.parse_blink(line)
                if 'ESACC' in line:
                    self.parse_saccade(line)
        # Convert the collected rows to a DataFrame once all lines are processed
        self.data_frame = pd.DataFrame(self.rows)
        return self.data_frame

        
    def assign_node(self,x, y, node_positions):
        def euclidean_distance(p1, p2):
            return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

        # Calculate radius for each node based on the nearest neighbor
        radii = [float('inf')] * len(node_positions)
        for i, node in enumerate(node_positions):
            for j, other_node in enumerate(node_positions):
                if i != j:
                    distance = euclidean_distance(node, other_node)
                    if distance < radii[i]:
                        radii[i] = distance / 2  
                        
        for index, (node, radius) in enumerate(zip(node_positions, radii)):
            distance = euclidean_distance(node, (x, y))
            if distance <= radius:
                return index  

        return -1  


        

    def parse_message(self, line):
        """ Parses MSG lines for time events and handles offset calculations. """
        msg_match = re.search(r"MSG\s+(\d+)\s+.*\"time\":\s+(\d+\.\d+).*\"event\":\s+\"([^\"]+)\"", line)
        if msg_match:
            t_el, t_py, self.event = msg_match.groups()
            t_el, t_py = float(t_el), float(t_py)
            t_el /= 1000  # Convert to seconds
            offset = t_py - t_el
            if np.isnan(self.current_offset) or "drift check" in self.event:
                self.current_offset = offset  # Update offset if the event is 'drift check' or first time
            if self.event == 'initialize':
                self.trial_index += 1
                self.visit = 0
                self.switch = 0
            if self.event == 'visit':
                self.visit += 1
            if self.event == 'switch':
                self.switch =+1
            
            self.rows.append({
                'Type': 'Message',
                'Event': self.event,
                'Visit': self.visit,
                'Switch': self.switch,
                'Time': t_el,
                'TimeEvent': t_py,
                'Offset': offset - self.current_offset,
                'trial_index':self.trial_index
            })

    def parse_fixation(self, line):
        """ Parses fixation data from EFIX lines. """
        fixation_match = re.search(r"EFIX\s+(L|R)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)", line)
        if fixation_match:
            eye, start, end, duration, x, y, pupil = fixation_match.groups()
            start, end, duration = map(lambda x: float(x) / 1000, [start, end, duration])
            x, y, pupil = map(float, [x, y, pupil])
            start += self.current_offset
            end += self.current_offset
            node = self.assign_node(x,y, self.node_positions)
            self.rows.append({'Type': 'Fixation', 'Start': start, 'End': end, 'Duration': duration, 'Node': node, 'X': x, 'Y': y, 'Pupil': pupil,  'trial_index':self.trial_index, 'event':self.event, 'visit':self.visit, 'switch':self.switch})

    def parse_gaze(self, line):
        """ Parses gaze data from lines that potentially contain gaze information. """
        gaze_match = re.search(r"(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)", line)
        if gaze_match:
            t, x, y = map(float, gaze_match.groups())
            t /= 1000  # Convert to seconds
            t += self.current_offset
            node = self.assign_node(x, y, self.node_positions)
            self.rows.append({'Type': 'Gaze', 'Time': t,'Node':node, 'X': x, 'Y': y, 'trial_index':self.trial_index, 'event':self.event, 'visit':self.visit, 'switch':self.switch})

    def parse_blink(self, line):
        """ Parses blink data from EBLINK lines. """
        blink_match = re.search(r"EBLINK\s+(\d+)\s+(\d+)\s+(\d+)", line)
        if blink_match:
            start, end, duration = map(lambda x: float(x) / 1000, blink_match.groups())
            start += self.current_offset
            end += self.current_offset
            self.rows.append({'Type': 'Blink', 'Start': start, 'End': end, 'Duration': duration, 'trial_index':self.trial_index, 'event':self.event, 'visit':self.visit, 'switch':self.switch})
    
    def parse_saccade(self, line):
        """
        Parses saccade data from ESACC lines.
        ESACC R 3216221 3216233 13 515.2 381.6 531.2 390.7 0.51 58
        """
        saccade_match = re.search(
            r"ESACC\s+(L|R)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)", line)
        if saccade_match:
            eye, start, end, duration, start_x, start_y, end_x, end_y, amplitude, peak_velocity = saccade_match.groups()
            start, end, duration = map(lambda x: float(x) / 1000, [start, end, duration])  # Convert time to seconds
            start_x, start_y, end_x, end_y, amplitude, peak_velocity = map(float, [start_x, start_y, end_x, end_y, amplitude, peak_velocity])
            start_node = self.assign_node(start_x, start_y, self.node_positions)
            end_node = self.assign_node(end_x, end_y, self.node_positions)

            self.rows.append({
                'Type': 'Saccade',
                'Eye': eye,
                'Start': start,
                'End': end,
                'Duration': duration,
                'Start_X': start_x,
                'Start_Y': start_y,
                'End_X': end_x,
                'End_Y': end_y,
                'Amplitude': amplitude,
                'Peak_Velocity': peak_velocity,
                'Start_Node': start_node,
                'End_Node': end_node,
                'trial_index': self.trial_index,
                'event': self.event,
                'visit': self.visit,
                'switch': self.switch
            })