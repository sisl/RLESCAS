# *****************************************************************************
# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# *****************************************************************************
# Copyright ã 2015, United States Government, as represented by the
# Administrator of the National Aeronautics and Space Administration. All
# rights reserved.  The Reinforcement Learning Encounter Simulator (RLES)
# platform is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable
# law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
# _____________________________________________________________________________
# Reinforcement Learning Encounter Simulator (RLES) includes the following
# third party software. The SISLES.jl package is licensed under the MIT Expat
# License: Copyright (c) 2014: Youngjun Kim.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED
# "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *****************************************************************************

using RLESMDPs
using SISLES.GenerativeModel
using RunCases

using CPUTime
using Dates

import Obj2Dict

function trajReplay(savefile::String; fileroot::String="", case::Case=Case())

  d = trajLoad(savefile)

  if isempty(fileroot)
    fileroot = string(getSaveFileRoot(savefile), "_replay")
  end

  return trajReplay(d; fileroot=fileroot, case=case)
end

function trajReplay(d::SaveDict; fileroot::String = "", case::Case=Case())

  sim_params = extract_params!(Obj2Dict.to_obj(d["sim_params"]), case, "sim_params")
  mdp_params = extract_params!(Obj2Dict.to_obj(d["mdp_params"]), case, "mdp_params")
  reward = sv_reward(d)

  sim = defineSim(sim_params)
  mdp = defineMDP(sim, mdp_params)
  action_seq = Obj2Dict.to_obj(d["sim_log"]["action_seq"])

  simLog = SimLog()
  addObservers!(simLog, mdp)

  reward = playSequence(getTransitionModel(mdp), action_seq)

  notifyObserver(sim, "run_info", Any[reward, sim.md_time, sim.hmd, sim.vmd, sim.label_as_nmac])

  #Save
  sav = d #copy original
  sav["sim_log"] = simLog #replace with new log

  replay_reward = sv_reward(d)  #there's rounding in logs, so need to compare the log version of rewards

  if replay_reward != reward
    warn("traj_save_load::trajReplay: replay reward is different than original reward")
  end

  fileroot = isempty(fileroot) ? "trajReplay$(enc)" : fileroot
  outfilename = trajSave(fileroot, sav)

  return outfilename
end
