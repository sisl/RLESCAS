#provides an interface to SaveDict, so that underlying format changes don't affect end-users

sv_simlog_names(d::SaveDict, field::String) = d["sim_log"]["var_names"][field]

sv_simlog_units(d::SaveDict, field::String) = d["sim_log"]["var_units"][field]

function sv_simlog_units(d::SaveDict, field::String, vname::String)

  sv_simlog_units(d, field)[sv_lookup_id(d, field, vname)]
end

function sv_simlog_data(d::SaveDict, field::String, aircraft_id::Int64)

  return d["sim_log"][field]["aircraft"]["$(aircraft_id)"]
end

function sv_simlog_data_vid(d::SaveDict, field::String, aircraft_id::Int64, vid::Union(String,Int64))

  var_id = sv_lookup_id(d, field, vid)

  return sv_simlog_data(d, field, aircraft_id)[var_id]
end

#return these times of this field (no aircraft id)
function sv_simlog_tdata(d::SaveDict, field::String, times::Vector{Int64}=Int64[])

  if isempty(times) #return all times
    times = sorted_times(d, field)
  end

  return map(t -> d["sim_log"][field]["time"]["$t"], times)
end

#same as above but filters for vid.  If vid is string, then a lookup is done,
#if already index, then it is directly used.
function sv_simlog_tdata_vid(d::SaveDict, field::String, vid::Union(String,Int64),
                             times::Vector{Int64}=Int64[])
  var_id = sv_lookup_id(d, field, vid) #returns identity if already an index

  return map(x -> x[var_id], sv_simlog_tdata(d, field, times))
end

#convert to float
function sv_simlog_tdata_vid_f(d::SaveDict, field::String, vid::Union(String,Int64),
                               times::Vector{Int64}=Int64[])

  convert(Vector{Float64}, sv_simlog_tdata_vid(d, field, vid, times))
end

#return these times of this field and this aircraft
function sv_simlog_tdata(d::SaveDict, field::String, aircraft_id::Int64, times::Vector{Int64}=Int64[])

  if isempty(times) #return all times
    times = sorted_times(d, field, aircraft_id)
  end

  return map(t -> d["sim_log"][field]["aircraft"]["$(aircraft_id)"]["time"]["$t"], times)
end

#same as above but filters for vid.  If vid is string, then a lookup is done,
#if already index, then it is directly used.
function sv_simlog_tdata_vid(d::SaveDict, field::String, aircraft_id::Int64,
                             vid::Union(String,Int64), times::Vector{Int64}=Int64[])
  var_id = sv_lookup_id(d, field, vid) #returns identity if already an index

  return map(x -> x[var_id], sv_simlog_tdata(d, field, aircraft_id, times))
end

#convert to float
function sv_simlog_tdata_vid_f(d::SaveDict, field::String, aircraft_id::Int64,
                               vid::Union(String,Int64), times::Vector{Int64}=Int64[])

  convert(Vector{Float64}, sv_simlog_tdata_vid(d, field, aircraft_id, vid, times))
end

#if already an index, check for validity, and just return it
function sv_lookup_id(d::SaveDict, field::String, vid::Int64; noerrors::Bool = false)

  if !noerrors && !(1 <= vid <= length(sv_simlog_names(d, field)))
    error("sv_lookup_id: vid is out of bounds")
  end

  return vid
end

function sv_lookup_id(d::SaveDict, field::String, vname::String; noerrors::Bool = false)

  i = findfirst(x->x == vname, sv_simlog_names(d, field))

  if !noerrors && i == 0
    error("get_id::variable name not found: $vname")
  end

  return i
end

function sorted_times(d::SaveDict, field::String, aircraft_id::Union(Int64,Nothing)=nothing)

  dtemp = d["sim_log"][field]

  if aircraft_id != nothing
    dtemp = dtemp["aircraft"]["$(aircraft_id)"]
  end

  if haskey(dtemp, "time")
    ts = collect(keys(dtemp["time"]))
    ts = int64(ts)
    sort!(ts)
  else
    ts = 0 #flag for time field not found
  end

  return ts
end

sv_num_aircraft(d::SaveDict, field::String = "wm") = length(d["sim_log"][field]["aircraft"])

sv_run_type(d::SaveDict) = d["run_type"]

sv_reward(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "reward")]

sv_nmac(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "nmac")]

sv_hmd(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "hmd")]

sv_vmd(d::SaveDict) = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "vmd")]

function sv_md_time(d::SaveDict)
  t_index = d["sim_log"]["run_info"][sv_lookup_id(d, "run_info", "md_time")] #md_time is the index
  sv_simlog_tdata_vid(d, "wm", 1, "t", [t_index])[1]
end

function sv_encounter_id(d::SaveDict)

  enc = -1
  enctype = "invalid"

  if haskey(d["sim_params"]["data"], "encounter_number")
    enc = Obj2Dict.to_obj(d["sim_params"]["data"]["encounter_number"])
    enctype = "encounter_number"
  elseif haskey(d["sim_params"]["data"], "encounter_seed")
    enc = Obj2Dict.to_obj(d["sim_params"]["data"]["encounter_seed"])
    enctype = "encounter_seed"
  else
    warn("sv_encounter_number: Cannot find required fields.")
  end

  return (enc, enctype)
end

is_nmac(file::String) = file |> trajLoad |> sv_nmac

nmacs_only(file::String) = is_nmac(file)
nmacs_only{T<:String}(files::Vector{T}) = filter(is_nmac, files)

function contains_only{T <: String}(filenames::Vector{T}, substr::String)

  filter(f -> contains(f, substr), filenames)
end
