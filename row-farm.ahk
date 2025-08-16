#MaxThreadsPerHotkey 2

profiles := [{ name: "Nether Warts", row_clear_time: 96000, void_drop_time: 3500, w_layer_swap_time: 0, layer_count: 5 }]

state := {
    profile_name: "",
    row_clear_time: 0,
    void_drop_time: 0,
    w_layer_swap_time: 0,
    layer_count: 0,
    is_active: false,
    is_paused: false,
    focus_lost: false,
    keys: { a_key: "a", d_key: "d", w_key: "w" },
    pause_check_interval: 500,
    show_pause_Message: true,

    debugging: false,
    added_time: 0,
    walked_time: 0,
    paused_time: 0,
    start_time: 0,
    interval_1: 0
}

state.current_key := state.keys.a_key
set_profile(profiles[1])
update_tray()

SetTimer(check_minecraft_window_focus, 2000)

F1::
F2::
{
    global state

    if (state.is_active) {
        state.is_paused := true
        result := MsgBox("Do you really want to quit the macro?", "Confirm", "YesNo")

        if (result = "No") {
            state.is_paused := false
            return
        }

        state.is_active := false
        state.is_paused := false
        state.focus_lost := false
    } else {
        run_farm(A_ThisHotkey = "F1" ? state.keys.d_key : state.keys.a_key)
    }
}

F3::
{
    global state

    if (!state.is_active)
        return

    state.is_paused := !state.is_paused
}

run_farm(start_key) {
    global state

    if(state.debugging) {
        state.start_time := getUnixTimestamp()
        state.added_time := 0
        state.walked_time := 0
        state.paused_time := 0
    }

    state.current_key := start_key
    state.is_active := true
    
    while (state.is_active) {
        loop state.layer_count {
            clear_row_optimized()
            
            if (!state.is_active)
                return

            if (state.w_layer_swap_time != 0)
                w_layer_swap()

            toggle_direction()
        }
        
        handle_void_drop()

        if(state.debugging) {
            state.interval_1 := getUnixTimestamp()
            interval_duration := state.interval_1 - state.start_time

            MsgBox(
                "added_time: " state.added_time "`n"
                "walked_time: " state.walked_time "`n"
                "paused_time: " state.paused_time "`n"
                "start_time: " state.start_time "`n"
                "interval_time: " state.interval_1 "`n"
                "interval_duration: " interval_duration
            )
        }
    }
}

clear_row_optimized() {
    global state

    total_time := state.row_clear_time + 50
    
    activate_current_buttons()
    
    elapsed_time := 0
    
    while (elapsed_time < total_time && state.is_active) {

        remaining_time := total_time - elapsed_time
        sleep_chunk := Min(state.pause_check_interval, remaining_time)
        
        sleep_start := A_TickCount
        Sleep sleep_chunk
        actual_sleep := A_TickCount - sleep_start
        
        elapsed_time += actual_sleep
        
        if(state.debugging) {
            state.walked_time += actual_sleep
            ToolTip("Row progress: " . Round((elapsed_time / total_time) * 100) . "%")
        }
        
        if (state.is_paused) {
            deactivate_current_buttons()
            handle_pause_state()
            if (state.is_active)
                activate_current_buttons()
        }
    }
    
    deactivate_current_buttons()
    ToolTip()
}

handle_void_drop() {
    global state
    
    if(state.debugging)
        state.walked_time += state.void_drop_time
    
    elapsed_void := 0
    
    while (elapsed_void < state.void_drop_time && state.is_active) {
        remaining_void := state.void_drop_time - elapsed_void
        sleep_chunk := Min(state.pause_check_interval, remaining_void)
        
        Sleep sleep_chunk
        elapsed_void += sleep_chunk
        
        if(state.debugging)
            ToolTip("Void drop: " . Round((elapsed_void / state.void_drop_time) * 100) . "%")
        
        if (state.is_paused) {
            handle_pause_state()
        }
    }
    
    ToolTip()
}

handle_pause_state() {
    global state
    
    pause_start := A_TickCount
    
    while (state.is_active && state.is_paused) {
        if (state.show_pause_Message)
            ToolTip("PAUSED - Press F3 to resume")

        Sleep state.pause_check_interval
        
        if(state.debugging)
            state.paused_time += state.pause_check_interval
    }
    
    if(state.debugging) {
        actual_pause := A_TickCount - pause_start
        state.paused_time += actual_pause
    }
    
    ToolTip()
}

activate_current_buttons() {
    global state
    Send "{" state.current_key " down}"
    Click "down"
}

deactivate_current_buttons() {
    global state
    Send "{" state.current_key " up}"
    Click "up"
}

w_layer_swap() {
    global state

    Send "{" state.keys.w_key " down}"
    
    if(state.debugging)
        state.walked_time += state.w_layer_swap_time 
    
    Sleep state.w_layer_swap_time + 50
    Send "{" state.keys.w_key " up}"
}

toggle_direction() {
    global state
    state.current_key := state.current_key == state.keys.a_key ? state.keys.d_key : state.keys.a_key
}

set_profile(profile, *) {
    global state

    if (state.is_active) {
        MsgBox("Please deactivate the macro first")
        return
    }

    state.profile_name := profile.name
    state.row_clear_time := profile.row_clear_time
    state.void_drop_time := profile.void_drop_time
    state.w_layer_swap_time := profile.w_layer_swap_time
    state.layer_count := profile.layer_count

    update_tray()
}

update_tray() {
    global state

    A_TrayMenu.Delete()

    A_TrayMenu.Add("Profile: " state.profile_name, (*) => 0)
    A_TrayMenu.Add("Row clear time: " state.row_clear_time, (*) => 0)
    A_TrayMenu.Add("Void drop time: " state.void_drop_time, (*) => 0)
    A_TrayMenu.Add("W layer swap time: " state.w_layer_swap_time, (*) => 0)
    A_TrayMenu.Add("Layer count: " state.layer_count, (*) => 0)
    A_TrayMenu.Add("Pause check interval: " state.pause_check_interval, (*) => 0)

    profileMenu := Menu()
    for i, profile in profiles {
        profileMenu.Add(profile.name, set_profile.Bind(profile))
    }

    A_TrayMenu.Add("Profiles", profileMenu)
    pause_state_message := state.show_pause_Message ? "enabled" : "disabled"
    A_TrayMenu.Add("Pause message: " pause_state_message, (*) => toggle_pause_message())
    A_TrayMenu.Add("Exit", (*) => ExitApp())
}

check_minecraft_window_focus() {
    global state

    if (!WinActive("ahk_exe javaw.exe")) {
        state.is_paused := true
    }
}

toggle_pause_message() {
    global state
    state.show_pause_Message := !state.show_pause_Message
    ToolTip()
    update_tray()
}
    
GetUnixTimestamp() {
    NowUTC := A_NowUTC
    NowUTC := DateDiff(NowUTC, 1970, 'S')
    Return NowUTC
}