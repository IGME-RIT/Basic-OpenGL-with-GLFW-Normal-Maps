/*
Title: Normal Maps
File Name: fragment.glsl
Copyright ? 2016
Author: David Erbelding
Written under the supervision of David I. Schwartz, Ph.D., and
supported by a professional development seed grant from the B. Thomas
Golisano College of Computing & Information Sciences
(https://www.rit.edu/gccis) at the Rochester Institute of Technology.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#version 400 core

in vec2 uv;
in mat3 tbn;

uniform sampler2D tex;
uniform sampler2D tex2;

void main(void)
{
	vec4 ambientLight = vec4(.1, .1, .3, 1);
	vec4 lightColor = vec4(1, .8, .3, 1);
	vec3 lightDir = vec3(-1, -1, -2);
	
	vec4 color = texture(tex, uv);

	// The normal from our texture is stored from 0 to 1, so we need to convert it to -1 to 1
	vec3 texnorm = normalize(vec3(texture(tex2, uv)) * 2.0 - 1.0);

	// Then we multiply our vector by the matrix that we calculated in the vertex shader.
	// This rotates the normal from texture space into world space!
	vec3 norm = tbn * texnorm;

	// After that, everything else is the same...


	// calculate diffuse lighting and clamp between 0 and 1
	float ndotl = clamp(-dot(normalize(lightDir), normalize(norm)), 0, 1); 

	// add diffuse lighting to ambient lighting and clamp a second time
	vec4 lightValue = clamp(lightColor * ndotl + ambientLight, 0, 1);

	// finally, sample from the texuture and multiply in the light.
	gl_FragColor = color * lightValue;
}