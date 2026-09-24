`default_nettype none

module spi_peripheral (
    input  wire      sclk,
    input  wire      clk,
    input  wire      rst_n,
    input  wire      cs,
    input  wire      copi,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

    reg [4:0]  spi_counter;
    reg [1:0]  sclk_sync;
    reg [1:0]  cs_sync;
    reg [1:0]  copi_sync;
    reg        sclk_prev;
    reg        cs_prev;
    reg [15:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_counter <= 1'b0;
            sclk_sync <= 1'b0;
            cs_sync <= 2'b11;
            copi_sync <= 1'b0;
            en_reg_out_7_0 <= 8'h0;
            en_reg_out_15_8 <= 8'h0;
            en_reg_pwm_7_0 <= 8'h0;
            en_reg_pwm_15_8 <= 8'h0;
            pwm_duty_cycle <= 8'h0;
        end else begin
            // metastability
            // first flip flop
            sclk_sync[0] <= sclk;
            cs_sync[0] <= cs;
            copi_sync[0] <= copi;

            // second flip flop
            sclk_sync[1] <= sclk_sync[0];
            cs_sync[1] <= cs_sync[0];
            copi_sync[1] <= copi_sync[0];

            // save previous values
            sclk_prev <= sclk_sync[1];
            cs_prev <= cs_sync[1];

            // received sclk pulse => store data into shift_reg
            if (!sclk_prev && sclk_sync[1] && !cs_sync[1]) begin
                // store current input value
                spi_counter <= spi_counter + 1'b1;
                shift_reg <= {shift_reg[14:0], copi_sync[1]}; 
            end else if (!cs_sync[1] && cs_prev) begin
                // reset, transaction starting
                shift_reg <= 1'b0;
                spi_counter <= 1'b0;
            end else if (spi_counter == 5'b10000) begin
                spi_counter <= 1'b0; // reset counter

                if (shift_reg[15]) begin // check read/write bit
                    if (shift_reg[14:8] == 8'h0) begin
                        en_reg_out_7_0 <= shift_reg[7:0];
                    end

                    if (shift_reg[14:8] == 8'h1) begin
                        en_reg_out_15_8 <= shift_reg[7:0];
                    end

                    if (shift_reg[14:8] == 8'h2) begin
                        en_reg_pwm_7_0 <= shift_reg[7:0];
                    end

                    if (shift_reg[14:8] == 8'h3) begin
                        en_reg_pwm_15_8 <= shift_reg[7:0];
                    end

                    if (shift_reg[14:8] == 8'h4) begin
                        pwm_duty_cycle <= shift_reg[7:0];
                    end
                end
            end
        end
    end

endmodule