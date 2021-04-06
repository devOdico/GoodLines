# Lines for Unity3D

This package provides lines with width defined in screen space. That is, the width of the line is given in pixels and the line's width will take up that many pixels regardless of where it is viewed from.

Features:

* Width defined in pixels
* Billboarding (making sure the flat line mesh is faced towards to camera) and scaling is handled in shaders. Fast and lines can be viewed from multiple cameras without looking broken.
* There is a pixel perfect version of the shader which tries to round off vertex positions to the center of pixels when lines are “pixel aligned”. This is mainly useful for orthographic projections i.e. 2D line drawings.

Limitations:

* Only two vertices per line segment joint. This means large line widths tend to look quite bad when they bend sharply (note that any bend will look sharp from some angle). These lines work best for 1 to about 5 pixel thick lines.
* Texturing the lines is currently not possible. Only solid, unlit colors.
* Lines cannot have transparency (I think this can be fixed just by adding the right combinations of keywords to the shaders though)
* The performance of the mesh generation itself could probably be a bit better. I haven't tested it, but animated lines with many segments might cause problems? Might also work fine. This article might be interesting for trying to optimize the mesh generation on the CPU side: https://www.raywenderlich.com/7880445-unity-job-system-and-burst-compiler-getting-started

These limitations could all be overcome with more work (although the first one probably requires rethinking how the core vertex shader works).

## Installation

*Unity can install packages directly from a git tag, but only from public repositories (we could open source this project?).*

1. Download the latest release package from the release page (the `.tgz` file): https://github.com/devOdico/GoodLines/releases
2. Then in the Unity editor to Window → Package Manager. In the package manager click the little plus (+) icon. The select add package from tarball and select the release you downloaded.

## Usage

To get started rendering some lines:

1. Add a new game object to the scene.
2. Add a `Line Mesh` component and a `Mesh Renderer` component (a mesh filter component will automatically be added as well).
3. Create a new Material (right click in the `Assets` folder → Create → Material).
4. Change the shader to GoodLines → Line.
5. On the `Mesh Renderer` component set the material for Element 0 to the newly created material.

This should draw a line at origin of the game object extending 1 unit in the x direction. If this is too small/big for the current scene the game object can be scaled up/down.

The width and color of the line can be changed using the material settings. See below for detailed explanation of all the shader settings.

There is currently no interface for setting the line itself through the Unity Editor, but the line can be set from a script. To do this:

1. Create a new script attached to the game object.
2. Get a reference to the line mesh component (for example by `var lm = GetComponent<LineMesh>()`).
3. Set the line using the `SetLinesFromPoints` method on the `LineMesh`. It takes a list of a list of points (`List<List<Vector3>>`). Each list defines a new line (so one `LineMesh` can contain multiple disjoint line segments).

### Example

Here is an example drawing a fancy wobbly spiral with 1999 sample points. (Note that despite the `ExecuteAlways` the script seems to not automatically rerun after having been changed without either starting the game or reattaching the script to the game object)

    using System.Collections.Generic;
    using System.Linq;
    using UnityEngine;

    [ExecuteAlways]
    [RequireComponent(typeof(LineMesh))]
    public class Spiral2D : MonoBehaviour
    {
        private LineMesh lineMesh;
        // Start is called before the first frame update
        void Start()
        {
            lineMesh = GetComponent<LineMesh>();

            var spiral = Enumerable.Range(1, 2000).Select(i => i/20.0f).Select(Spiral);

            lineMesh.SetLinesFromPoints(new List<List<Vector3>>() {spiral.ToList()});
        }

        private Vector3 Spiral(float param) {
            return new Vector3(Mathf.Cos(param), Mathf.Sin(param), Mathf.Sin(param*8)*0.25f) * param;
        }
    }

## Shader settings

This section provides a more in depth description of the different shader options. These are all edited through the material. 

There are two different shaders to choose from in the GoodLines category (which is added to the unity editor after installing the package). Line and PixelPerfect. Line is the standard shader. Below are the options it supports:

**Thickness**: Width of the line in pixels  
**Thickness Multiplier**: Multiplied with thickness to get actual thickness. Is there for getting higher thickness values while not making the thickness slider completely unusable. Probably only useful in conjunction with the perspective setting.  
**Color**: The Color of the line. Transparency not currently supported.  
**Miter Threshold**: With this option set to 1 the shader always does a [miter join](https://duckduckgo.com/?q=miter+join&t=canonical&iax=images&ia=images). This has diverging behavior for very sharp angles where it tends to look broken. So the shader can do an alternate type of join (TODO: Add section explaining the inner workings of the shader? It is based on [this](https://mattdesl.svbtle.com/drawing-lines-is-hard) but with more stuff added). This value sets a threshold where it switches to this type of join. It should probably always be close to but not quite 1. By setting it to 0 the switchover point is at 90 degress and at -1 the alternative join is always used (which has diverging behavior at very shallow angles).  
**Perspective**: Adds some perspective to the line rendering. At 0 there is no perspective and the thickness is the pixel width as advertised. At 1 there is true perspective. For any non-zero value the thickness becomes a bit weird since it is both dependent on the screen resolution, but also on the world space distances between camera and line. In general higher thickness values are necessary. The thickness multiplier can be used to go above 10. I am not sure if this is useful. Maybe it should just be removed.

The pixel perfect shader is mainly intended for mostly static 2D drawings using an orthogonal projection, which use anti aliasing and which contains straight lines aligned to the pixel grid (up down or left right). In this scenario lines can sometimes end up “between” pixels. This can cause problems. For example, black lines with a width of 1 pixel will generally be drawn as greyish lines 2 pixels thick to simulate a line between 2 pixels. For almost any other situation than the very specific one listed above, you probably don't want to use this shader.

The pixel perfect shader tries to round off vertex positions so, they always land in the center of a pixel if they are part of a straight line aligned to the pixel grid, but not otherwise. To this end, two extra options are present:

**Pixel Alignment**: At 0 rounded vertices are rounded to the center of a pixel. This is what you want for lines of odd (1,3,5 etc) width. For even width lines you might want to set this to 1 (or -1). If you draw a 2 thickness lines with this option set to 1 it will become 3 wide with a fully colored in center and two washed out pixels on either side in order to simulate the center of the line being directly on top of a pixel. By setting this option to 1 or -1 you can push the whole thing by half a pixel in one direction or the other so, the line becomes exactly 2 fully colored in pixels wide.  
**Pixel Align Threshold**: Influences how close to perfectly aligned to the pixel grid a line segment has to be before the rounding happens. Should be very close to zero (0.01 seems good).
