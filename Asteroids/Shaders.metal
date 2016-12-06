#import <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[ position ]];
    float4 color;
};

vertex Vertex tile_vertex_shader(device float4x4 *uniforms [[ buffer(0) ]],
                                 device float4x4 *instanceUniforms [[ buffer(1) ]],
                                 device Vertex *vertices [[ buffer(2) ]],
                                 unsigned int vid [[ vertex_id ]]) {
    Vertex v = vertices[vid];
    v.position = uniforms[0] * instanceUniforms[0] * v.position;
    return v;
}

fragment half4 tile_fragment_shader(Vertex v [[ stage_in ]]) {
    return half4(v.color);
}