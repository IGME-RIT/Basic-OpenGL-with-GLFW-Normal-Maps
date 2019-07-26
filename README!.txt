Documentation Author: Niko Procopi 2019

This tutorial was designed for Visual Studio 2017 / 2019
If the solution does not compile, retarget the solution
to a different version of the Windows SDK. If you do not
have any version of the Windows SDK, it can be installed
from the Visual Studio Installer Tool

Welcome to the Normal Mapping Tutorial!
Prerequesites: OBJ loader

Comparison1 Screenshot:
Left:   texture
Middle: texture + normal map
Right:  texture + normal map + mipmapping

Comparison2 Screenshot:
Left:   texture + normal map
Middle: texture + normal map + mipmapping
Right:  texture + normal map + anisotropy

Every vertex has a normal, which indicates the direction that a polygon faces
Usually, with lighting, we pass the Vertex Normal to the rasterizer, which interpolates
The per-vertex normal into a per-pixel normal, and then we use that per-pixel normal for 
NdotL lighting.

With normal mapping, we can have every pixel have its own unique normal, to give the illusion
of surface detail

When should we use Normal Mapping:
If you have an extremely powerful computer, you can fill the game with high-poly models.
If you want to optimize the game, you can render low-poly models, and create the illusion
of high-poly models with Normal Mapping

When should we not use Normal Mapping:
-If there is no lighting applied to the model, then the surface appears as flat as it would
have originally looked, without normal mapping
-If you can afford to render a high-poly model, then there is no need to put a normal map
on a low-poly model

How to create a normal map:
To create a normal map, you need a high-poly model and a low-poly model.
For simplicity, image you are working with bricks (just like this tutorial)
The low-poly model would be one square
The high-poly model would have millions of polygons for every detail of the bricks
With Maya or Blender, you can use a tool that transfers vertex normals from the high-poly
model, into the pixels of the low-poly model. Each pixel of the normal map texture, 
represents a vertex normal from the high-poly model. 
Here is a video: https://www.youtube.com/watch?v=pfFRHaIIhO4

How does a vertex normal turn into a pixel?
Each normal has an X-direction, a Y-direction, and a Z-direction
The X-direction ranges from -1 to 1 (left to right)
The Y-direction ranges from -1 to 1 (down to up)
The Z-direction ranges from -1 to 1 (in to out)
Images have three color channels that we often see: Red, Green, and Blue.
Red, Green, and Blue all range from 0 to 1 (dark to bright)
Blender and Maya encode the vertex normal into the pixel color
X gets encoded into the Red channel
Y gets encoded into the Green channel
Z gets encoded into the Blue channel
Blender and Maya divide X by 2 (turning -1 to 1, into -0.5 to 0.5 )
	then add 0.5 to the result (turning -0.5 to 0.5, into 0 to 1)
	then that final value is put into the red channel
The same is done with Y and Z with Green and Blue
When it is time to extract this data, we need to convert the color back into a normal

How it works:
With our low-poly model, rather than using rasterized Vertex Normals for our NdotL 
equations, we will use a normal from the Normal Map for NdotL. Then the lighting of
the low-poly model will look like the lighting of a high-poly model. As a bonus, because
of how NdotL works, we get small shadows where a normal faces away from the light (see demo)

How to implement (intro):
In this tutorial, it is already done, but you can try it yourself by
copying and pasting OBJ Loader as starter-code, then grab the Normal map
PNG from the Assets folder of this tutorial.

How to implement (part 1):
In your fragment shader, you should have "uniform sampler2D tex;"
This texture is for your color (obviously). Add another for the normal map.
Personally, I added the line "uniform sampler2D tex2;", but you can call it
whatever you want. Next, in main.cpp, you can see we have the name
of the color texture variable in GLSL:
	char colorTexFS[] = "tex";
Add another for the Normal Map:
	char normalTexFS[] = "tex2";
Next, we need the path of the normal map
The path of the color texture is already set like this:
	char colorTexFile[] = "../Assets/BrickColor.png";
Add another for the normal map:
	char normalTexFile[] = "../Assets/BrickNormal.png";
After that, the normal map needs to be applied to the material
The color texture is already set like this:
	material->SetTexture(colorTexFS, new Texture(colorTexFile));
Next, add the normal map to the material:
	material->SetTexture(normalTexFS, new Texture(normalTexFile));

Test your code:
If you run the program right now, it should look just like the 
unmodified OBJ Loader. If you change "texture(tex, uv);" to 
"texture(tex2, uv);", then you should see the normal map.
This means you are ready for Part 2

How to implement (part 2):
We need to convert a pixel (RGB) (0 to 1) into a normal vector (-1 to 1)
For an explanation on why, look at the section in this documentation titled:
"How does a vertex normal turn into a pixel?"
First we get the pixel from the texture:
	vec4 normalFromTex = texture(tex2, uv);
To convert the pixel back into a normal, simply do the inverse formula:
	// normalize(vec3(normalFromTex)) ranges from 0 to 1
	// * 2.0 ranges from 0 to 2
	// - 1.0 ranges from -1 to 1
	vec3 decompNormalFromTex = normalize(vec3(normalFromTex)) * 2.0 - 1.0;
We now have the normal. There is one problem, this normal is in tangent-space
and not world-space. Meaning, if we rotate the polygon, the normal does not rotate.
If the camera were looking directly at the plane, then this normal would be correct.
We need to take this normal, and rotate it with respect to the polygon's rotation,
and we also need to take tangents and bitangents into consideration (new topic).

How to implement (part 3):
Go back to the OBJ loader and get tangents, then put them in the vertex buffer
A "tangent" is the direction that the texture's X-axis moves in
You can see how in the CalculateTangents(); function in mesh.cpp
The CalculateTangents(); algorithm is exactly the same for every OBJ loader.
Implementation can vary depending on the person (in terms of variable naming), but its
always the same. The original algorithm was written in 2001, you can see it here:
http://www.terathon.com/code/tangent.html
This link is referenced in every book, and in Unity documentation

How to implement (part 4):
Go to vertex shader
We already grab the normal form the vertex in the vertex buffer here:
	layout(location = 2) in vec3 in_normal;
Now we need to grab the tangent:
	layout(location = 3) in vec3 in_tangent;
The fragment shader needs a normal, a tangent, and a bitangent.
The bitangent will be calculated with the normal and tangent
We already send the UV and Normal to the rasterizer like this:
	out vec2 uv;
	out vec3 normal;
Now we add the tangent and the bitangent:
	out vec3 tangent;
	out vec3 bitangent;
We already calculate the vertex normal by applying the world matrix to the normal:
	normal = mat3(worldMatrix) * in_normal;
Now we need to do the same thing to the tangent:
	tangent = mat3(worldMatrix) * in_tangent;
Then we calculate the bitangent by doing the cross product 
	bitangent = normalize(cross(tangent, normal));
Tangent is the direction that the X-axis of the texture points in
Bitangent is the direction that the Y-axis of the texture points in
The tangent and normal are always perpendicular, so the cross product gives use
a vector that is perpendicular to both of them (which is bitangent)

How to implement (part 5):
Go to fragment shader
We already take in the normal from the rasterizer like this:
	in vec3 normal;
Now we have to do the same to the tangent and bitangent
	in vec3 tangent;
	in vec3 bitangent;
We normalize the normal before it goes to the rasterizer, and after it
comes out of the rasterizer. We have to do the same with tangent and bitangent
After that, we make a TBN matrix with the tangent, bitangent, and interpolated Vertex Normal
	mat3 tbn = mat3(tangent, bitangent, normal);

Very important: The TBN matrix is a rotation matrix
We've seen Translation, Scaling, and Rotation matrices, 
TBN is just like any other rotation matrix

Next, we apply the TBN matrix to the normal that was decompressed from the RGB
color of the normal map:
	vec3 finalPerPixelNormal = tbn * decompNormalFromTex;
Then we use finalPerPixelNormal as our normal in the NdotL equation

Am I done yet?
If the pillars are darker than the floor,
If the underside of the roof is dark,
If more surface detail is clearly visible
You did it!

How to improve:
If you want to make the textures clearer, look into Mipmapping
Try making the light move, that is when Normal Mapping looks its best
Try looking into specular light, to make surfaces look shiny
	