#import <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[ position ]];
    float4 color;
};

vertex Vertex basic_vertex(device float4x4 *uniforms [[ buffer(0) ]],
                           device float4x4 *instanceUniforms [[ buffer(1) ]],
                           device Vertex *vertices [[ buffer(2) ]],
                           unsigned int vid [[ vertex_id ]]) {
    Vertex v = vertices[vid];
    v.position = uniforms[0] * instanceUniforms[0] * v.position;
    return v;
}

fragment half4 passthrough_fragment(Vertex v [[ stage_in ]]) {
    return half4(v.color);
}






struct VertexWithTex {
    float4 position [[ position ]];
    float2 uv;
};

vertex VertexWithTex basic_transform_vertex(device float4x4 *uniforms [[ buffer(0) ]],
                                            device VertexWithTex *verts [[ buffer(1) ]],
                                            unsigned int vid [[ vertex_id ]]) {
    VertexWithTex v = verts[vid];
    v.position = uniforms[0] * v.position;
    return v;
}

fragment half4 basic_texture_fragment(VertexWithTex v [[ stage_in ]],
                               texture2d<float> texture [[ texture(0) ]] ) {
    constexpr sampler s(coord::pixel, filter::linear);
    
    float4 color = texture.sample(s, v.uv);
    return half4(color);
}



// Debug entity selection
vertex Vertex highlight_entity_vertex(device float4x4 *uniforms [[ buffer(0) ]],
                                      device float4x4 *instanceUniforms [[ buffer(1) ]],
                                      device Vertex *vertices [[ buffer(2) ]],
                                      unsigned int vid [[ vertex_id ]]) {
    Vertex v = vertices[vid];
    float4x4 scale = float4x4(1);
    scale[0][0] = 1.2;
    scale[1][1] = 1.2;
    v.position = uniforms[0] * instanceUniforms[0] * scale * v.position;
    return v;
}

fragment half4 highlight_entity_fragment(Vertex v [[ stage_in ]]) {
    return half4(1.0, 0.0, 0.0, 1.0);
}











