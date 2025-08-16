#MaxThreadsPerHotkey 2

profiles := [
    { name: "Nether Warts",  row_clear_time: 96000, void_drop_time: 3500, w_layer_swap_time: 0,  layer_count: 5 },
]


state := {
    profile_name:"",
    row_clear_time: 0,
    void_drop_time: 0,
    w_layer_swap_time: 0, 
    layer_count: 0,
    is_active: false,
    is_paused:false,
    focus_lost:false,
    keys: {a_key:"a", d_key:"d", w_key:"w"},
    step_interval: 250,
    show_pause_Message:true
}

state.current_key:= state.keys.a_key
set_profile(profiles[1])
update_tray()

SetTimer(check_minecraft_window_focus, state.step_interval)

F1::
F2::
{
    global state

    if (state.is_active) {
        state.is_active:=false
        state.is_paused:=false
        state.focus_lost:=false
    } else {
        
        run_farm(A_ThisHotkey = "F1" ? state.keys.d_key : state.keys.a_key)
    }
}

F3::
{
    global state

    if (!state.is_active)
        return

    state.is_paused:=state.is_paused?false:true
}

run_farm(start_key){
    global state

    state.current_key:=start_key

    state.is_active:=true
    while(state.is_active){
        Loop state.layer_count
        {
            clear_row()
            if(state.is_active==false)
                return

            if(state.w_layer_swap_time!=0)
                w_layer_swap()
            
            toggle_direction()
        }
        Sleep state.void_drop_time
    }
}

clear_row()
{
    global state

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
    Click "up"
}

do_row_step(interval_time)
{
    global state

    check_for_pause()

    Send "{" state.current_key " down}"
    Click "down"
    Sleep interval_time
}

check_for_pause(){
    global state 

    while (state.is_active&&state.is_paused)
    {
        if(state.show_pause_Message)
            ToolTip("paused")

        Send "{" state.current_key " up}"
        Click "up"
        Sleep state.step_interval
    }

    ToolTip
}

w_layer_swap(){
    global state
    
    Send "{" state.keys.w_key " down}"
    Sleep state.w_layer_swap_time
    Send "{" state.keys.w_key " up}"
}

toggle_direction()
{
    global state

    state.current_key:=state.current_key==state.keys.a_key?state.keys.d_key:state.keys.a_key
}

rand_offset_time()
{
    return Random(200, 400)
}

set_profile(profile,*){
    global state

    if(state.is_active){
        MsgBox("Please deactivate the macro first")
        return
    }

    state.profile_name:=profile.name
    state.row_clear_time:=profile.row_clear_time
    state.void_drop_time:=profile.void_drop_time
    state.w_layer_swap_time:=profile.w_layer_swap_time
    state.layer_count:=profile.layer_count

    update_tray()
}

update_tray(){
    global state

    A_TrayMenu.Delete()

    A_TrayMenu.Add("Name: " state.profile_name, (*) => 0)
    A_TrayMenu.Add("Row clear time: " state.row_clear_time, (*) => 0)
    A_TrayMenu.Add("Void drop time: " state.void_drop_time, (*) => 0)
    A_TrayMenu.Add("W layer swap time: " state.w_layer_swap_time, (*) => 0)
    A_TrayMenu.Add("Layer count: " state.layer_count, (*) => 0)

    profileMenu := Menu()
    for i, profile in profiles {
        profileMenu.Add(profile.name, set_profile.Bind(profile))
    }


    A_TrayMenu.Add("Profiles", profileMenu)
    pause_state_message:=state.show_pause_Message?"enabled":"disabled"
    A_TrayMenu.Add("Pause message: " pause_state_message,(*) => toggle_pause_message())
    A_TrayMenu.Add("Exit", (*) => ExitApp())
}

check_minecraft_window_focus(){
    global state

    if (!WinActive("ahk_exe javaw.exe")) {
        state.is_paused := true
    }
}

toggle_pause_message(){
    global state

    state.show_pause_Message:=state.show_pause_Message?false:true
    ToolTip

    update_tray()
}
