#MaxThreadsPerHotkey 2

global keys := { a_key: "a", d_key: "d", w_key: "w" }

; Naming scheme : <plot_length>x<layercount> <name> @ <speed> (<pitch>|<yaw>)
global profiles := [
    { name: "5x5 Nether Warts @ 116 (|)", row_clear_time: 96000, void_drop_time: 3500, layer_swap_time: 0, layer_count: 5 , key_left:keys.a_key, key_right:keys.d_key, key_layer_swap:keys.w_key},
    { name: "test ", row_clear_time: 7000, void_drop_time: 1000, layer_swap_time: 0, layer_count: 2 , key_left:keys.a_key, key_right:keys.d_key, key_layer_swap:keys.w_key}
,]

global moods := [
    { name:"attentive", click_delay: 0, overshoot_chance: 0, overshoot_duration: 0, overshoot_duration_variable: 0, mood_min_duration: 10, mood_max_duration: 1200000, mood_chance: 0.30 },
    { name:"inattentive", click_delay: 100, overshoot_chance: 0.2, overshoot_duration: 5, overshoot_duration_variable: 3000, mood_min_duration: 10, mood_max_duration: 1800000,mood_chance: 0.45 },
    { name:"distracted", click_delay: 250, overshoot_chance: 0.1, overshoot_duration: 10, overshoot_duration_variable: 5000, mood_min_duration: 5, mood_max_duration: 900000, mood_chance: 0.25 },
]

global state := {
    ; profile
    current_profile: profiles[1],
    ; programm state
    is_active: false,
    is_paused: false,
    focus_lost: false,
    current_key: profiles[1].key_left,
    ; settings
    polling_interval: 100,
    show_pause_Message: true,
    ; moods
    current_mood: moods[1],
    previous_mood: moods[1],
    current_mood_duration: moods[1].mood_min_duration,
    force_attentive_mood: false,
    ; debugging
    debugging: true,
    added_time: 0,
    walked_time: 0,
    paused_time: 0,
    start_time: 0,
    interval_1: 0
}

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
        run_farm(A_ThisHotkey = "F1" ? state.current_profile.key_left : state.current_profile.key_right)
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

    if (state.debugging) {
        state.start_time := getUnixTimestamp()
        state.added_time := 0
        state.walked_time := 0
        state.paused_time := 0
    }

    state.is_active := true

    while (state.is_active) {

        state.current_key := start_key

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

    total_time := state.current_profile.row_clear_time + Random(0, 250) + get_mood_overshoot()

    activate_current_buttons()

    elapsed_time := 0

    while (elapsed_time < total_time && state.is_active) {

        remaining_time := total_time - elapsed_time
        sleep_chunk := Min(state.polling_interval, remaining_time)

        sleep_start := A_TickCount
        Sleep sleep_chunk
        actual_sleep := A_TickCount - sleep_start

        elapsed_time += actual_sleep

        if (state.current_mood_duration > 0) {
            state.current_mood_duration -= state.polling_interval
        } else {
            switch_mood()
        }

        if (state.debugging) {
            state.walked_time += actual_sleep
            ToolTip("Row progress: " . Round((elapsed_time / total_time) * 100) . "%`nCurrent mood: " state.current_mood.name)
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

activate_current_buttons() {
    global state

    deviation := get_click_deviation()

    Click "down"
    PreciseSleep(500 + deviation[1])
    Send "{" state.current_key " down}"
    PreciseSleep(deviation[2])
}

deactivate_current_buttons() {
    global state

    deviation := get_click_deviation()

    Send "{" state.current_key " up}"
    PreciseSleep(deviation[1])
    Click "up"
    PreciseSleep(deviation[2])
}

get_click_deviation() {
    global state

    rand := Random(50, 100)
    deviator := Random(0, 50)

    mood_delay := state.force_attentive_mood ? moods[1].click_delay : state.current_mood.click_delay

    return [rand+ mood_delay, deviator] 
}

layer_swap() {
    global state

    Send "{" state.current_profile.key_layer_swap " down}"

    if (state.debugging)
        state.walked_time += state.current_profile.layer_swap_time

    Sleep state.current_profile.layer_swap_time + 50
    Send "{" state.current_profile.key_layer_swap " up}"
}

toggle_direction() {
    global state
    state.current_key := state.current_key == state.current_profile.key_left ? state.current_profile.key_right : state.current_profile.key_left
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

    selected_mood_index := 0

    for index, chance in chances {
        current_threshold += chances[index]

        if (selected_mood_index == 0 && current_threshold <= roll) {
            selected_mood_index := index
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

    state.current_profile:=profile

    update_tray()
}

update_tray() {
    global state

    A_TrayMenu.Delete()

    A_TrayMenu.Add("Profile: " state.current_profile.name, (*) => 0)
    A_TrayMenu.Add("Row clear time: " state.current_profile.row_clear_time, (*) => 0)
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
