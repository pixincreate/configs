// # Constants
// divisions of grid
const float repeats = 30.;
// number of layers
const float layers = 21.;
// star colors
const vec3 white = vec3(0.8); // Set star color to pure white
const vec3 blue = vec3(0.5, 0.7, 1.0); // Bluish color for distant stars

const float TTL = 10.0;

// # Helper Functions


/**
 * Generate a 1D pseudo-random number based on the input 2D vector.
 * @param {vec2} p - Input 2D vector.
 * @returns {float} - Pseudo-random number.
 */
float N21(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

/**
 * Generate a 2D pseudo-random vector based on the input 2D vector.
 * @param {vec2} p - Input 2D vector.
 * @returns {vec2} - Pseudo-random 2D vector.
 */
vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(p + n));
}

/**
 * Create a 2x2 scaling matrix from the input 2D vector.
 * @param {vec2} _scale - 2D scaling factor.
 * @returns {mat2} - 2x2 scaling matrix.
 */
mat2 scale(vec2 _scale) {
    return mat2(_scale.x, 0.0,
        0.0, _scale.y);
}

/**
 * Generate 2D Perlin noise based on the input 2D coordinates.
 * @param {vec2} st - Input 2D coordinates.
 * @returns {float} - Perlin noise value.
 */
float noise(in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = N21(i);
    float b = N21(i + vec2(1.0, 0.0));
    float c = N21(i + vec2(0.0, 1.0));
    float d = N21(i + vec2(1.0, 1.0));

    // Smooth Interpolation
    vec2 u = f * f * (3.0 - 2.0 * f); // Cubic Hermite Curve

    // Mix 4 corners percentages
    return mix(a, b, u.x) +
        (c - a) * u.y * (1.0 - u.x) +
        (d - b) * u.x * u.y;
}

/**
 * Generate layered Perlin noise with adjustable octaves and scale.
 * @param {vec2} uv - Input 2D UV coordinates.
 * @param {int} octaves - Number of noise octaves.
 * @param {float} pscale - Perlin noise scale factor.
 * @returns {float} - Layered Perlin noise value.
 */
float perlin2(vec2 uv, int octaves, float pscale) {
    float col = 1.;
    float initScale = 4.;
    for (int l; l < octaves; l++) {
        float val = noise(uv * initScale);
        if (col <= 0.01) {
            col = 0.;
            break;
        }
        val -= 0.01;
        val *= 0.5;
        col *= val;
        initScale *= pscale;
    }
    return col;
}

/**
 * Generate a starfield effect based on the input UV coordinates and time offset.
 * @param {vec2} uv - Input 2D UV coordinates.
 * @param {float} offset - Time offset for the starfield animation.
 * @returns {vec3} - Star color.
 */
vec3 stars(vec2 uv, float offset) {
    float timeScale = -(pow(iTime, 2) + offset) / layers;
    float trans = fract(timeScale);
    float newRnd = floor(timeScale);
    vec3 col = vec3(0.);

    // Translate uv then scale for center
    uv -= vec2(0.5);
    uv = scale(vec2(trans)) * uv;
    uv += vec2(0.5);

    // Create square aspect ratio
    uv.x *= iResolution.x / iResolution.y;

    // Create boxes
    uv *= repeats;

    // Get position
    vec2 ipos = floor(uv);

    // Return uv as 0 to 1
    uv = fract(uv);

    // Calculate random xy and size
    vec2 rndXY = N22(newRnd + ipos * (offset + 1.)) * 0.9 + 0.05;
    float rndSize = N21(ipos) * 100. + 200.;

    vec2 j = (rndXY - uv) * rndSize;
    float sparkle = 1. / dot(j, j);

    // Apply Doppler effect based on distance from center
    float distance = length(uv - vec2(0.5));
    vec3 starColor = mix(white, blue, distance * 2.0);

    col += starColor * sparkle;

    col *= smoothstep(1., 0.8, trans);
    return col; // Return pure white stars only
}

// # Rendering Functions
/**
 * Render the starfield effect.
 * @param {out vec4} fragColor - Output color.
 * @param {in vec2} fragCoord - Input fragment coordinates.
 */
void renderStarField(out vec4 fragColor, in vec2 fragCoord) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord / iResolution.xy;

    vec3 col = vec3(0.);

    for (float i = 0.; i < layers; i++) {
        col += stars(uv, i);
    }

    // Output to screen
    // fragColor = vec4(col,1.0);
    // Sample the terminal screen texture including alpha channel
    vec4 terminalColor = texture(iChannel0, uv);

    // Make a mask that is 1.0 where the terminal content is not black
    float mask = 1 - step(0.5, dot(terminalColor.rgb, vec3(1.0)));
    vec3 blendedColor = mix(terminalColor.rgb, col, mask);

    // Apply terminal's alpha to control overall opacity
    fragColor = vec4(blendedColor, terminalColor.a);
}

/**
 * Disable the shader by displaying the terminal screen texture.
 * @param {out vec4} fragColor - Output color.
 * @param {in vec2} fragCoord - Input fragment coordinates.
 */
void disableShader(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}

// # Main Function
/**
 * Main entry point for the shader.
 * @param {out vec4} fragColor - Output color.
 * @param {in vec2} fragCoord - Input fragment coordinates.
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    if (iTime < TTL) {
         renderStarField(fragColor, fragCoord);
    } else {
         disableShader(fragColor, fragCoord);
    }
}

