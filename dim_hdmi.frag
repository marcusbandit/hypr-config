precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform int wl_output;

void main() {
    vec4 color = texture2D(tex, v_texcoord);

    if (wl_output == 0) {
        color.rgb *= 1.0000;
    }

    gl_FragColor = color;
}
