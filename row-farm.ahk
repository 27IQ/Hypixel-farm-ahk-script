#MaxThreadsPerHotkey 2

profiles := [{ name: "Nether Warts", row_clear_time: 96000, void_drop_time: 3500, w_layer_swap_time: 0, layer_count: 5 }, 
]

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
    step_interval: 100,
    show_pause_Message: true,

    debugging: true,
    added_time:0,
    walked_time:0,
    paused_time:0,
    start_time:0,
    interval_1:0
}

state.current_key := state.keys.a_key
set_profile(profiles[1])
update_tray()

SetTimer(check_minecraft_window_focus, state.step_interval)

F1::
F2::
{
    global state

    if (state.is_active) {

        state.is_paused := true
        result := MsgBox("Do you really want to quit the macro?", "Confirm", "YesNo")

        if (result = "No")
            return

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

    state.is_paused := state.is_paused ? false : true
}

run_farm(start_key) {
    global state

    if(state.debugging)
        state.start_time:=getUnixTimestamp()

    state.current_key := start_key

    state.is_active := true
    while (state.is_active) {
        loop state.layer_count {
            clear_row()
            if (state.is_active == false)
                return

            if (state.w_layer_swap_time != 0)
                w_layer_swap()

            toggle_direction()

            if(state.debugging){
                state.interval_1:=getUnixTimestamp()
                interval_duration:=state.interval_1-state.start_time

                MsgBox
                (
                "added_time: " state.added_time "`n"
                "walked_time: " state.walked_time "`n"
                "paused_time: " state.paused_time "`n"
                "start_time: " state.start_time "`n"
                "interval_time: " state.interval_1 "`n"
                "interval_duration: " interval_duration
                )
            }
        }
        Sleep state.void_drop_time
    }
}

clear_row() {
    global state

    row_time_left := state.row_clear_time + rand_offset_time()

    already_stepping := false

    while (row_time_left > 0 && state.is_active) {
        if (row_time_left > state.step_interval) {
            row_time_left -= state.step_interval
            current_interval := state.step_interval
        } else {
            current_interval := row_time_left
            row_time_left := 0
        }

        do_row_step(current_interval, already_stepping)
        already_stepping := true

        if(state.debugging){
            ToolTip(state.added_time)
        }
    }

    deactivate_current_buttons()
}

do_row_step(interval_time, already_stepping) {
    global state

    was_paused := check_for_pause()

    if (was_paused || !already_stepping)
        activate_current_buttons()

    if(state.debugging)
        state.walked_time+=interval_time

    Sleep interval_time
}

activate_current_buttons() {
    Sleep short_rand_offset_time()
    Send "{" state.current_key " down}"
    Sleep short_rand_offset_time()
    Click "down"
}

deactivate_current_buttons() {
    Sleep short_rand_offset_time()
    Send "{" state.current_key " up}"
    Sleep short_rand_offset_time()
    Click "up"
}

check_for_pause() {
    global state

    was_paused := false

    if (state.is_active && state.is_paused) {
        deactivate_current_buttons()

        was_paused := true
    }

    while (state.is_active && state.is_paused) {
        if (state.show_pause_Message)
            ToolTip("paused")

        if(state.debugging)
            state.paused_time+=state.step_interval

        Sleep state.step_interval
    }

    ToolTip

    return was_paused
}

w_layer_swap() {
    global state

    Send "{" state.keys.w_key " down}"
    if(state.debugging)
        state.walked_time+=state.w_layer_swap_time 
    
    Sleep state.w_layer_swap_time + rand_offset_time()
    Send "{" state.keys.w_key " up}"
}

toggle_direction() {
    global state

    state.current_key := state.current_key == state.keys.a_key ? state.keys.d_key : state.keys.a_key
}

short_rand_offset_time() {
    global state
    rand:=Random(1, 50)
    state.added_time+=rand

    return rand
}

rand_offset_time() {
    global state
    rand:=Random(50, 100)
    state.added_time+=rand

    return rand
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

    state.show_pause_Message := state.show_pause_Message ? false : true
    ToolTip

    update_tray()
}
    
GetUnixTimestamp() {
    NowUTC := A_NowUTC
    NowUTC := DateDiff(NowUTC, 1970, 'S')
    Return NowUTC
}