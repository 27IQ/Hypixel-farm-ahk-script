global row_clear_time:=5000
global void_drop_time:=3500
global layer_count:=5
global is_active:=false
global directions:= {left:"left", right:"right"}
global keys:={a_key:"a", d_key:"d"}
global step_interval:=500

F1::
{
    global is_active
    if(is_active)
    {
        is_active:=false
        return
    } 

    global current_direction:=directions.right
    global current_key:=keys.a_key
    
    is_active:=true

    Loop layer_count
    {
        clear_row()
        toggle_direction()
    }
}

F2::
{
    global is_active
    if(is_active)
    {
        is_active:=false
        return
    } 
    
    global current_direction:=directions.left
    global current_key:=keys.d_key

    is_active:=true

    Loop layer_count
    {
        clear_row()
        toggle_direction()
    }
}

clear_row()
{
    row_time_left:=row_clear_time+rand_offset_time()

    while(row_time_left>0 && is_active)
    {
        if(row_time_left>step_interval){
            row_time_left-=step_interval
            current_interval:=step_interval
        }else{
            current_interval_:=row_time_left
            row_time_left:=0
        }
            
        do_row_step(current_interval)
    }

    Send "{" current_key " up}"
}

do_row_step(interval_time)
{
    Send "{" current_key " down}"
    Sleep interval_time
}

toggle_direction()
{
    if(current_direction==directions.left)
    {
        global current_direction:=directions.right
        global current_key:=keys.a_key
    }
    else
    {
        global current_direction:=directions.left
        global current_key:=keys.d_key
    }
}

rand_offset_time()
{
    return Random() 50 200
}