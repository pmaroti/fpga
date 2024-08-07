module sinlt(
    input [7:0] phase, 
    output reg [7:0] val // it needs to be reg type as we should drive the output from somewhere
    );

always @(phase) begin
//https://www.jdoodle.com/execute-nodejs-online
//for(i=0;i<256;i++) { console.log("8'b" + i.toString(2).padStart(8, '0')+": val = " + Math.round(128+Math.sin(i*2*Math.PI/256)*127)+";" )}
    case (phase)
        8'b00000000: val = 128;
        8'b00000001: val = 131;
        8'b00000010: val = 134;
        8'b00000011: val = 137;
        8'b00000100: val = 140;
        8'b00000101: val = 144;
        8'b00000110: val = 147;
        8'b00000111: val = 150;
        8'b00001000: val = 153;
        8'b00001001: val = 156;
        8'b00001010: val = 159;
        8'b00001011: val = 162;
        8'b00001100: val = 165;
        8'b00001101: val = 168;
        8'b00001110: val = 171;
        8'b00001111: val = 174;
        8'b00010000: val = 177;
        8'b00010001: val = 179;
        8'b00010010: val = 182;
        8'b00010011: val = 185;
        8'b00010100: val = 188;
        8'b00010101: val = 191;
        8'b00010110: val = 193;
        8'b00010111: val = 196;
        8'b00011000: val = 199;
        8'b00011001: val = 201;
        8'b00011010: val = 204;
        8'b00011011: val = 206;
        8'b00011100: val = 209;
        8'b00011101: val = 211;
        8'b00011110: val = 213;
        8'b00011111: val = 216;
        8'b00100000: val = 218;
        8'b00100001: val = 220;
        8'b00100010: val = 222;
        8'b00100011: val = 224;
        8'b00100100: val = 226;
        8'b00100101: val = 228;
        8'b00100110: val = 230;
        8'b00100111: val = 232;
        8'b00101000: val = 234;
        8'b00101001: val = 235;
        8'b00101010: val = 237;
        8'b00101011: val = 239;
        8'b00101100: val = 240;
        8'b00101101: val = 241;
        8'b00101110: val = 243;
        8'b00101111: val = 244;
        8'b00110000: val = 245;
        8'b00110001: val = 246;
        8'b00110010: val = 248;
        8'b00110011: val = 249;
        8'b00110100: val = 250;
        8'b00110101: val = 250;
        8'b00110110: val = 251;
        8'b00110111: val = 252;
        8'b00111000: val = 253;
        8'b00111001: val = 253;
        8'b00111010: val = 254;
        8'b00111011: val = 254;
        8'b00111100: val = 254;
        8'b00111101: val = 255;
        8'b00111110: val = 255;
        8'b00111111: val = 255;
        8'b01000000: val = 255;
        8'b01000001: val = 255;
        8'b01000010: val = 255;
        8'b01000011: val = 255;
        8'b01000100: val = 254;
        8'b01000101: val = 254;
        8'b01000110: val = 254;
        8'b01000111: val = 253;
        8'b01001000: val = 253;
        8'b01001001: val = 252;
        8'b01001010: val = 251;
        8'b01001011: val = 250;
        8'b01001100: val = 250;
        8'b01001101: val = 249;
        8'b01001110: val = 248;
        8'b01001111: val = 246;
        8'b01010000: val = 245;
        8'b01010001: val = 244;
        8'b01010010: val = 243;
        8'b01010011: val = 241;
        8'b01010100: val = 240;
        8'b01010101: val = 239;
        8'b01010110: val = 237;
        8'b01010111: val = 235;
        8'b01011000: val = 234;
        8'b01011001: val = 232;
        8'b01011010: val = 230;
        8'b01011011: val = 228;
        8'b01011100: val = 226;
        8'b01011101: val = 224;
        8'b01011110: val = 222;
        8'b01011111: val = 220;
        8'b01100000: val = 218;
        8'b01100001: val = 216;
        8'b01100010: val = 213;
        8'b01100011: val = 211;
        8'b01100100: val = 209;
        8'b01100101: val = 206;
        8'b01100110: val = 204;
        8'b01100111: val = 201;
        8'b01101000: val = 199;
        8'b01101001: val = 196;
        8'b01101010: val = 193;
        8'b01101011: val = 191;
        8'b01101100: val = 188;
        8'b01101101: val = 185;
        8'b01101110: val = 182;
        8'b01101111: val = 179;
        8'b01110000: val = 177;
        8'b01110001: val = 174;
        8'b01110010: val = 171;
        8'b01110011: val = 168;
        8'b01110100: val = 165;
        8'b01110101: val = 162;
        8'b01110110: val = 159;
        8'b01110111: val = 156;
        8'b01111000: val = 153;
        8'b01111001: val = 150;
        8'b01111010: val = 147;
        8'b01111011: val = 144;
        8'b01111100: val = 140;
        8'b01111101: val = 137;
        8'b01111110: val = 134;
        8'b01111111: val = 131;
        8'b10000000: val = 128;
        8'b10000001: val = 125;
        8'b10000010: val = 122;
        8'b10000011: val = 119;
        8'b10000100: val = 116;
        8'b10000101: val = 112;
        8'b10000110: val = 109;
        8'b10000111: val = 106;
        8'b10001000: val = 103;
        8'b10001001: val = 100;
        8'b10001010: val = 97;
        8'b10001011: val = 94;
        8'b10001100: val = 91;
        8'b10001101: val = 88;
        8'b10001110: val = 85;
        8'b10001111: val = 82;
        8'b10010000: val = 79;
        8'b10010001: val = 77;
        8'b10010010: val = 74;
        8'b10010011: val = 71;
        8'b10010100: val = 68;
        8'b10010101: val = 65;
        8'b10010110: val = 63;
        8'b10010111: val = 60;
        8'b10011000: val = 57;
        8'b10011001: val = 55;
        8'b10011010: val = 52;
        8'b10011011: val = 50;
        8'b10011100: val = 47;
        8'b10011101: val = 45;
        8'b10011110: val = 43;
        8'b10011111: val = 40;
        8'b10100000: val = 38;
        8'b10100001: val = 36;
        8'b10100010: val = 34;
        8'b10100011: val = 32;
        8'b10100100: val = 30;
        8'b10100101: val = 28;
        8'b10100110: val = 26;
        8'b10100111: val = 24;
        8'b10101000: val = 22;
        8'b10101001: val = 21;
        8'b10101010: val = 19;
        8'b10101011: val = 17;
        8'b10101100: val = 16;
        8'b10101101: val = 15;
        8'b10101110: val = 13;
        8'b10101111: val = 12;
        8'b10110000: val = 11;
        8'b10110001: val = 10;
        8'b10110010: val = 8;
        8'b10110011: val = 7;
        8'b10110100: val = 6;
        8'b10110101: val = 6;
        8'b10110110: val = 5;
        8'b10110111: val = 4;
        8'b10111000: val = 3;
        8'b10111001: val = 3;
        8'b10111010: val = 2;
        8'b10111011: val = 2;
        8'b10111100: val = 2;
        8'b10111101: val = 1;
        8'b10111110: val = 1;
        8'b10111111: val = 1;
        8'b11000000: val = 1;
        8'b11000001: val = 1;
        8'b11000010: val = 1;
        8'b11000011: val = 1;
        8'b11000100: val = 2;
        8'b11000101: val = 2;
        8'b11000110: val = 2;
        8'b11000111: val = 3;
        8'b11001000: val = 3;
        8'b11001001: val = 4;
        8'b11001010: val = 5;
        8'b11001011: val = 6;
        8'b11001100: val = 6;
        8'b11001101: val = 7;
        8'b11001110: val = 8;
        8'b11001111: val = 10;
        8'b11010000: val = 11;
        8'b11010001: val = 12;
        8'b11010010: val = 13;
        8'b11010011: val = 15;
        8'b11010100: val = 16;
        8'b11010101: val = 17;
        8'b11010110: val = 19;
        8'b11010111: val = 21;
        8'b11011000: val = 22;
        8'b11011001: val = 24;
        8'b11011010: val = 26;
        8'b11011011: val = 28;
        8'b11011100: val = 30;
        8'b11011101: val = 32;
        8'b11011110: val = 34;
        8'b11011111: val = 36;
        8'b11100000: val = 38;
        8'b11100001: val = 40;
        8'b11100010: val = 43;
        8'b11100011: val = 45;
        8'b11100100: val = 47;
        8'b11100101: val = 50;
        8'b11100110: val = 52;
        8'b11100111: val = 55;
        8'b11101000: val = 57;
        8'b11101001: val = 60;
        8'b11101010: val = 63;
        8'b11101011: val = 65;
        8'b11101100: val = 68;
        8'b11101101: val = 71;
        8'b11101110: val = 74;
        8'b11101111: val = 77;
        8'b11110000: val = 79;
        8'b11110001: val = 82;
        8'b11110010: val = 85;
        8'b11110011: val = 88;
        8'b11110100: val = 91;
        8'b11110101: val = 94;
        8'b11110110: val = 97;
        8'b11110111: val = 100;
        8'b11111000: val = 103;
        8'b11111001: val = 106;
        8'b11111010: val = 109;
        8'b11111011: val = 112;
        8'b11111100: val = 116;
        8'b11111101: val = 119;
        8'b11111110: val = 122;
        8'b11111111: val = 125;
    endcase
end

endmodule
