#!/usr/bin/env python
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os

import tensorflow as tf
import util
import sys

def read_doc_keys(fname):
    keys = set()
    with open(fname) as f:
        for line in f:
            keys.add(line.strip())
    return keys

if __name__ == "__main__":
  # config = util.initialize_from_env(eval_test=True)

  experiments_conf = "experiments.conf"
  if len(sys.argv) > 2:
      experiments_conf = sys.argv[2]
  config = util.initialize_from_env(eval_test=experiments_conf)
  model = util.get_model(config)
  saver = tf.train.Saver()
  log_dir = config["log_dir"]
  with tf.Session() as session:
    model.restore(session)
    # Make sure eval mode is True if you want official conll results
    model.evaluate(session, official_stdout=True, eval_mode=True)
