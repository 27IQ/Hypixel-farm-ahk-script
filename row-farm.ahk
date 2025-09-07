#MaxThreadsPerHotkey 2

global keys := { a_key: "a", d_key: "d", w_key: "w", s_key: "s" }

global directions := { left: "left", right: "right" }

; Naming scheme : <plot_length>x<layercount> <name> @ <speed> (<pitch>|<yaw>)    pitch and yaw should be facing centric
global profiles := [
    { name: "5x5 Nether Warts @ 116 (0|0)", left_row_clear_time: 96000, right_row_clear_time: 96000,void_drop_time: 3500, layer_swap_time: 0, layer_count: 5, keys_left: [keys.a_key], keys_right: [keys.d_key],keys_layer_swap: [keys.w_key] }, 
    { name: "5x4 Mushroom @ 126 (25L|0)", left_row_clear_time: 92000,right_row_clear_time: 97000, void_drop_time: 3500, layer_swap_time: 0, layer_count: 4, keys_left: [keys.w_key,keys.a_key], keys_right: [keys.d_key], keys_layer_swap: [keys.w_key] }
]

global moods := [
    { name: "attentive", click_delay: 0, overshoot_chance: 0, overshoot_duration: 0,overshoot_duration_variable: 0, mood_min_duration: 600000, mood_max_duration: 720000, mood_chance: 0.30,click_delay_miss: 0.0 }, 
    { name: "inattentive", click_delay: 100, overshoot_chance: 0.2, overshoot_duration: 5000,overshoot_duration_variable: 3000, mood_min_duration: 600000, mood_max_duration: 108000, mood_chance: 0.45,click_delay_miss: 0.0 }, 
    { name: "distracted", click_delay: 250, overshoot_chance: 0.1, overshoot_duration: 10000,overshoot_duration_variable: 5000, mood_min_duration: 300000, mood_max_duration: 540000, mood_chance: 0.25,click_delay_miss: 0.5 },
]

global state := {
    ; profile
    current_profile: profiles[1],
    ; programm state
    is_active: false,
    is_paused: false,
    focus_lost: false,
    current_direction: "",
    ; settings
    polling_interval: 100,
    show_pause_Message: true,
    ; moods
    current_mood: moods[1],
    previous_mood: moods[1],
    current_mood_duration: moods[1].mood_min_duration,
    force_attentive_mood: false,
    ; debugging
    debugging: false,
    added_time: 0,
    walked_time: 0,
    paused_time: 0,
    start_time: 0,
    interval_1: 0
}

set_profile(profiles[1])
update_tray()

SetTimer(check_minecraft_window_focus, state.polling_interval)

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

        if (A_ThisHotkey = "F2") {
            state.current_direction := directions.right
        } else {
            state.current_direction := directions.left
        }

        run_farm()
    }
}

F3::
{
    global state

    if (!state.is_active)
        return

    state.is_paused := !state.is_paused
}

run_farm() {
    global state

    if (state.debugging) {
        state.start_time := getUnixTimestamp()
        state.added_time := 0
        state.walked_time := 0
        state.paused_time := 0
    }

    state.is_active := true
    state.is_paused := false

    while (state.is_active) {

        loop state.current_profile.layer_count {
            clear_row()

            if (!state.is_active)
                return

            if (state.current_profile.layer_swap_time != 0)
                layer_swap()

            toggle_direction()
        }

        handle_void_drop()

        if (state.debugging) {
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

clear_row() {
    global state

    mood_overshoot:=get_mood_overshoot()
    total_time := get_current_row_clear_time() + Random(0, 250) + mood_overshoot

    set_current_buttons("down")

    elapsed_time := 0

    while (elapsed_time < total_time && state.is_active) {

        remaining_time := total_time - elapsed_time
        sleep_chunk := Min(state.polling_interval, remaining_time)

        if (state.is_paused) {
            set_current_buttons("up")
            handle_pause_state()
            if (state.is_active)
                set_current_buttons("down")
        }

        sleep_start := A_TickCount
        Sleep sleep_chunk
        actual_sleep := A_TickCount - sleep_start

        if (state.is_paused) {
            set_current_buttons("up")
            handle_pause_state()
            if (state.is_active)
                set_current_buttons("down")
        }

        elapsed_time += actual_sleep

        if (state.current_mood_duration > 0) {
            state.current_mood_duration -= actual_sleep
        }else{
            switch_mood()
        }

        if (state.debugging) {
            state.walked_time += actual_sleep
        }

        ToolTip("Row progress: " . Round((elapsed_time / total_time) * 100) . "%`nCurrent mood: " state.current_mood.name "`nRow time: " total_time "`nElapsed time: " elapsed_time "`nMood Time: " mood_overshoot)

        if (state.is_paused) {
            set_current_buttons("up")
            handle_pause_state()
            if (state.is_active)
                set_current_buttons("down")
        }
    }

    set_current_buttons("up")
    ToolTip()
}

handle_void_drop() {
    global state

    if (state.debugging)
        state.walked_time += state.current_profile.void_drop_time

    elapsed_void := 0

    while (elapsed_void < state.current_profile.void_drop_time && state.is_active) {
        remaining_void := state.current_profile.void_drop_time - elapsed_void
        sleep_chunk := Min(state.polling_interval, remaining_void)

        Sleep sleep_chunk
        elapsed_void += sleep_chunk

        if (state.debugging)
            ToolTip("Void drop: " . Round((elapsed_void / state.current_profile.void_drop_time) * 100) . "%")

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

        Sleep state.polling_interval

        if (state.debugging)
            state.paused_time += state.polling_interval
    }

    if (state.debugging) {
        actual_pause := A_TickCount - pause_start
        state.paused_time += actual_pause
    }

    ToolTip()
}

set_current_buttons(toggle) {
    global state

    deviation := get_click_deviation(get_current_direction_keys().Length)
    miss := get_click_delay_miss()
    current_key_order := get_current_key_order()

    if (toggle == "down") {
        PreciseSleep(10)
        Click toggle
        PreciseSleep((miss ? 0 : 500) + deviation[1])

        loop deviation.Length - 1 {
            Send "{" current_key_order[A_Index] " " toggle "}"
            PreciseSleep(deviation[A_Index + 1])
        }

    } else if (toggle == "up") {
        PreciseSleep(10)

        loop deviation.Length - 1 {
            Send "{" current_key_order[A_Index] " " toggle "}"
            PreciseSleep(deviation[A_Index + 1])
        }

        Click toggle
        PreciseSleep(deviation[1])
    }
}

get_click_deviation(count) {
    global state

    rand := Random(50, 100)
    mood_delay := state.force_attentive_mood ? moods[1].click_delay : state.current_mood.click_delay

    result := [rand + mood_delay]

    loop count {
        result.Push(Random(0, 70))
    }

    return result
}

get_current_key_order() {
    global state

    min := 1
    current_keys := get_current_direction_keys()
    max := current_keys.Length

    results := []

    while (results.Length < current_keys.Length
    ) {
        pull := Random(min, max)

        if (results.Length == 0) {
            results.Push(current_keys[pull])
            continue
        }

        for value in results {
            if (value == current_keys[pull]) {
                continue
            } else {
                results.Push(current_keys[pull])
            }
        }
    }

    return results
}

get_click_delay_miss() {
    global state

    pull := Random(0, 1)

    return pull == 1 ? true : false
}

layer_swap() {
    global state

    keys := state.current_profile.keys_layer_swap

    deviation := get_click_deviation(keys.Length * 2)

    loop (keys.Length) {
        Send "{" state.current_profile.keys_layer_swap[A_Index] " down}"
        PreciseSleep(deviation[A_Index])
    }

    if (state.debugging)
        state.walked_time += state.current_profile.layer_swap_time

    PreciseSleep(state.current_profile.layer_swap_time)

    loop (keys.Length) {
        Send "{" state.current_profile.keys_layer_swap[A_Index] " up}"
        PreciseSleep(deviation[keys.Length + A_Index])
    }
}

toggle_direction() {
    global state
    state.current_direction := state.current_direction == directions.left ? directions.right : directions.left
}

get_current_direction_keys() {
    global state

    return state.current_direction == directions.left ? state.current_profile.keys_left : state.current_profile.keys_right
}

get_current_row_clear_time() {
    global state

    return state.current_direction == directions.left ? state.current_profile.left_row_clear_time : state.current_profile.right_row_clear_time
}

get_mood_overshoot() {
    global state

    overshoot := 0

    if (state.force_attentive_mood || state.current_mood.overshoot_duration == 0)
        return overshoot

    roll := Random(0, 1)

    if (state.current_mood.overshoot_chance <= roll) {
        min_dur := state.current_mood.overshoot_duration - state.current_mood.overshoot_duration_variable
        max_dur := state.current_mood.overshoot_duration + state.current_mood.overshoot_duration_variable
        overshoot := Random(min_dur, max_dur)
    }

    return overshoot
}

switch_mood() {
    global state

    new_mood := get_next_mood()

    state.previous_mood := state.current_mood
    state.current_mood := new_mood
    state.current_mood_duration := Random(state.current_mood.mood_min_duration, state.current_mood.mood_max_duration)
}

get_next_mood() {
    chances := [moods[1].mood_chance, moods[2].mood_chance, moods[3].mood_chance]

    current_threshold := 0
    roll := Random(0, 1)

    selected_mood_index := 1

    loop chances.Length {
        current_threshold += chances[A_Index]

        if (selected_mood_index == 1 && current_threshold <= roll) {
            selected_mood_index := A_Index
        }
    }

    return moods[selected_mood_index]
}

set_profile(profile, *) {
    global state

    if (state.is_active) {
        MsgBox("Please deactivate the macro first")
        return
    }

    state.current_profile := profile

    update_tray()
}

update_tray() {
    global state

    A_TrayMenu.Delete()

    A_TrayMenu.Add("Profile: " state.current_profile.name, (*) => 0)
    A_TrayMenu.Add("Left row clear time: " state.current_profile.left_row_clear_time, (*) => 0)
    A_TrayMenu.Add("Right row clear time: " state.current_profile.right_row_clear_time, (*) => 0)
    A_TrayMenu.Add("Void drop time: " state.current_profile.void_drop_time, (*) => 0)
    A_TrayMenu.Add("W layer swap time: " state.current_profile.layer_swap_time, (*) => 0)
    A_TrayMenu.Add("Layer count: " state.current_profile.layer_count, (*) => 0)

    profileMenu := Menu()
    for i, profile in profiles {
        profileMenu.Add(profile.name, set_profile.Bind(profile))
    }

    A_TrayMenu.Add("Profiles", profileMenu)
    pause_state_message := state.show_pause_Message ? "enabled ✅" : "disabled ❌"
    A_TrayMenu.Add("Pause message: " pause_state_message, (*) => toggle_pause_message())
    force_attentive_mood_message := state.force_attentive_mood ? "enabled ✅" : "disabled ❌"
    A_TrayMenu.Add("Force attentive mood: " force_attentive_mood_message, (*) => toggle_attentive_mood_force())
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

toggle_attentive_mood_force() {
    global state
    state.force_attentive_mood := !state.force_attentive_mood
    update_tray()
}

GetUnixTimestamp() {
    NowUTC := A_NowUTC
    NowUTC := DateDiff(NowUTC, 1970, 'S')
    return NowUTC
}

PreciseSleep(ms) {
    start := A_TickCount
    end := start + ms

    if (ms > 20)
        Sleep ms - 15

    while (A_TickCount < end) {
        DllCall("Sleep", "UInt", 1)
    }
}