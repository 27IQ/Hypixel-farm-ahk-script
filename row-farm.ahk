#MaxThreadsPerHotkey 2

state := {
    row_clear_time: 96000,
    void_drop_time: 3500,
    layer_count: 5,
    is_active: false,
    keys: {a_key:"a", d_key:"d"},
    step_interval: 500,
}

state.current_key:= state.keys.a_key


F1::
F2::
{
    if (state.is_active) {
        state.is_active:=false
    } else {
        run_farm(A_ThisHotkey = "F1" ? state.keys.d_key : state.keys.a_key)
    }
}
return

run_farm(start_key){
    state.current_key:=start_key

    state.is_active:=true

    Loop state.layer_count
    {
        clear_row()
        if(state.is_active==false)
            return
        
        toggle_direction()
    }
}

clear_row()
{
    row_time_left:=state.row_clear_time+rand_offset_time()
    while(row_time_left>0 && state.is_active)
    {
        if(row_time_left>state.step_interval){
            row_time_left-=state.step_interval
            current_interval:=state.step_interval
        }else{
            current_interval:=row_time_left
            row_time_left:=0
        }
            
        do_row_step(current_interval)
    }

    Send "{" state.current_key " up}"
}

do_row_step(interval_time)
{
    Send "{" state.current_key " down}"
    Sleep interval_time
}

toggle_direction()
{
    state.current_key:=state.current_key==state.keys.a_key?state.keys.d_key:state.keys.a_key
}

rand_offset_time()
{
    return Random() 50 200
}