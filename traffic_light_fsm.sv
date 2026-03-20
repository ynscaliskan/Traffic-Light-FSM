module traffic_light_fsm (
    input  logic clk,
    input  logic reset,
    input  logic TAORB,  // == 1 (Traffic at A and B clear)  /   == 0 (Traffic at B and A clear) 
    output logic [2:0] LA, // 0 = red , 1 = yellow , 2 = green
    output logic [2:0] LB
);

    //STATE REGISTERS
    typedef enum logic [1:0] {
        S0 = 2'b00, //LA green, LB red
        S1 = 2'b01, //LA yellow, LB red
        S2 = 2'b10, //LA red, LB green
        S3 = 2'b11  //LA red, LB yellow
    } state_t;

    state_t current_state, next_state;
    logic [2:0] timer; //not 5 seconds but 5 clock cycle

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= S0;
            timer <= 0;
        end 
        else begin

            current_state <= next_state;
            if (current_state == S1 || current_state == S3) begin // checking for cycle states
                if (timer < 5)
                    timer <= timer + 1;
                else
                    timer <= 0;
            end 
            else begin   // else we hold the timer at 0
                timer <= 0;
            end
        end
    end

    // NEXT STATE LOGIC
    always_comb begin
        case (current_state)
            S0: begin
                // If TAORB is false, it means there is traffic at street B. 
                // Move to S1 to start the transition for street B.
                if (~TAORB) next_state = S1; 
                // Keep Street A green as long as TAORB is true.
                else        next_state = S0; 
            end
            S1: begin
                // Hold the yellow light for 5 time units as required.
                // Transition to S2 (Street B Green) once the timer hits 5.
                if (timer == 5) next_state = S2; 
                else            next_state = S1; 
            end
            S2: begin
                // If TAORB becomes true, traffic has arrived at Street A.
                // Move to S3 to prepare Street B for a red light.
                if (TAORB)  next_state = S3; 
                // Keep Street B green while TAORB remains false.
                else        next_state = S2; 
            end
            S3: begin
                // Similar to S1, hold the yellow light for 5 time units.
                // Return to S0 (Street A Green) once the timer hits 5.
                if (timer == 5) next_state = S0; 
                else            next_state = S3; 
            end
            default: next_state = S0;
        endcase
    end

    //OUTPUT LOGIC
    always_comb begin
        LA = 3'b001; // Red
        LB = 3'b001; // Red
        
        case (current_state) //LA green, LB red
            S0: begin 
                LA = 3'b100; 
                LB = 3'b001; 
            end 

            S1: begin //LA yellow, LB red
                LA = 3'b010; 
                LB = 3'b001; 
            end 

            S2: begin //LA red, LB green
                LA = 3'b001; 
                LB = 3'b100; 
            end  

            S3: begin //LA red, LB yellow
                LA = 3'b001; 
                LB = 3'b010; 
            end 
        endcase
    end

endmodule