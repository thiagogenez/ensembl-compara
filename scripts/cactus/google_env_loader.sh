#!/usr/bin/env bash

# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ----  Function to wait the GPU to be loaded ----

get_elapsed_time(){
  echo "$SECONDS - $1" | bc -l
}


check_gpu(){
  start_time=$SECONDS
  stop_condition=600 #seconds
  status=1
 
  while [ $status -ne 0 ]; do
    nvidia-smi &>/dev/null
    status=$?
 
    # GPU loaded =)
    [ $status -eq 0 ] && break
 
    elapsed=$(get_elapsed_time $start_time)
 
    # GPU not loaded until now =/
    [ "$elapsed" -gt $stop_condition ] && break
 
    sleep 10
  done

  # HACKY to make nvidia-smi faster -> this must be included when the image is build
  sudo nvidia-persistenced --persistence-mode
}
 
# ---- the following is for Cactus ----
 
# load singularity module
module load singularity
 
# Docker Image for "normal" Cactus (without-gpu binaries)
export CACTUS_IMAGE="/apps/cactus/current/bin/cactus.sif"
 
# Docker Image for Cactus with GPU binaries
export CACTUS_GPU_IMAGE="/apps/cactus/current/bin/cactus-gpu.sif"
 
# Create local folder to add some binaries
LOCAL_SCRIPTS="$HOME/.local/scripts"
[ -d "$LOCAL_SCRIPTS" ] || mkdir -p "$LOCAL_SCRIPTS"
 
# Download scripts
URL="https://raw.githubusercontent.com/thiagogenez/ensembl-compara/feature/cactus_scripts/scripts/cactus"
CACTUS_SCRIPTS=(cactus_tree_prepare.py cactus_batcher.py)
for i in "${CACTUS_SCRIPTS[@]}"; do
	wget --quiet "$URL/$i" -O "$LOCAL_SCRIPTS/$i"
	chmod +x "$LOCAL_SCRIPTS/$i"
done 

#UPDATE PATH
export PATH=${LOCAL_SCRIPTS}:$PATH

# mount /data
#[ -d /data ] && mount /data
 
# if this is a GPU-enable node, forcing the bash to stop until GPUs are loaded
#if [[ -d /usr/local/cuda/ ]]; then
#  check_gpu
#fi