#ifndef TOON_MAIN_LIGHT_INCLUDED
#define TOON_MAIN_LIGHT_INCLUDED

void MainLight_float(out float3 Direction, out float3 Color)
{
#if defined(SHADERGRAPH_PREVIEW)

    Direction = normalize(float3(0.5, 0.5, -0.5));
    Color = float3(1.0, 1.0, 1.0);

#else

    Direction = normalize(_MainLightPosition.xyz);
    Color = _MainLightColor.rgb;

#endif
}

void MainLight_half(out half3 Direction, out half3 Color)
{
#if defined(SHADERGRAPH_PREVIEW)

    Direction = normalize(half3(0.5, 0.5, -0.5));
    Color = half3(1.0, 1.0, 1.0);

#else

    Direction = normalize(_MainLightPosition.xyz);
    Color = _MainLightColor.rgb;

#endif
}

#endif
