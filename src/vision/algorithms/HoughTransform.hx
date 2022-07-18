package vision.algorithms;

import haxe.ds.Vector;
#if js
import js.Browser;
#end
import vision.ds.Line2D;
import vision.ds.LineSegment2D;
import vision.ds.Image;

/**
	A Hough Transform implementation by [ShaharMS](https://www.github.com/ShaharMS).

	## What is The Hough Transform?

	The Hough transform is a computer vision technique, commonly used to identify lines within an image.

	The only knowledge you need prior to understanding the algorithm is that lines can be represented 
	by either:
	 - two points `(x1, y1)` `(x2, y2)`, using the equation `y - y1 = m(x - x1)`
	 - two values, called `theta` and `rho`:
		- The first (theta) is the angle of the line
		- The second (rho) is the shortest distance from that line to the origin.

	## How does it work?

	The algorithm basically works like this:

	1. Create a large matrix where one axis of the matrix corresponds to theta and one to rho. This matrix is called the accumulator and is said to represent the "Hough space" of the image. Initialize this matrix by each entry being 0.
	1. Create a grayscale image
	1. Find the edges in that image (for example using the canny algorithm)
	1. For each point in those edges:
	1. Calculate many lines defined by theta and rho radiating out from that point. Each theta should have the same angle of difference to each other and each rho is calculated based on the coordinate of the point and the theta. For each of these lines, add a 1 to the corresponding entry in the accumulator matrix.
	1. When you have a filled in accumulator, find a number of local maxima within that accumulator. Each local maxima corresponds to a line in the image, so if you want to find 10 lines you should pick out the 10 local maxima that have the largest values in the accumulator matrix.
	1. Transform the local maxima in the accumulator back to lines using their corresponding theta and rho values.
	1. To visualize the result, overlay these lines on your original image.

**/
class HoughTransform {
	/**
		Uses the Hough Transform to generate an accumulator based on the
		image provided.

		@param image The image to be transformed.

		@return The image generated by the Hough Transform.
	**/
	public static function generateTransformed(image:Image):Image {
		var accumulator = new Image(361, Math.round(Math.sqrt(image.width * image.width + image.height * image.height)));

		return accumulator;
	}
    #if js

	public static function jsExample() {
		var THICKNESS = 2;

		var drawing = Browser.document.createCanvasElement();
		var houghSp = Browser.document.createCanvasElement();

		var ctx = drawing.getContext2d();
		var HSctx = houghSp.getContext2d();

		var drawingMode = false;

		var drawingWidth = drawing.width;
		var drawingHeight = drawing.height;

		var numAngleCells = 360;
		var rhoMax = Math.sqrt(drawingWidth * drawingWidth + drawingHeight * drawingHeight);
		var accum = new Vector(numAngleCells);
        var cosTable = new Vector<Float>(numAngleCells);
		var sinTable = new Vector<Float>(numAngleCells);

		// Set the size of the Hough space.
		var border = 20;
		houghSp.width = numAngleCells + border + border;
		houghSp.height = Std.int(rhoMax + border + border);

		HSctx.fillStyle = 'rgba(0,0,0,.5)';
		HSctx.strokeStyle = 'rgba(0,0,0,.5)';

		HSctx.beginPath();
		HSctx.moveTo(border, border);
		HSctx.lineTo(border, rhoMax + border);
		HSctx.lineTo(numAngleCells + border, rhoMax + border);
		HSctx.stroke();

		HSctx.font = "10px Arial";
		HSctx.fillText("Rho", 5, border);
		HSctx.fillText("Theta", numAngleCells, rhoMax + border + border / 2);

		HSctx.fillStyle = 'rgba(0,0,0,.1)';

		function drawInHough(rho, thetaIndex) {
			HSctx.beginPath();
			HSctx.fillRect(thetaIndex + border, rho, 1, 1);
			HSctx.closePath();
		}

		function findMaxInHough() {
			var max = 0;
			var bestRho = 0;
			var bestTheta = 0;
			for (i in 0...360) {
				for (j in 0...accum[i].length) {
					if (accum[i][j] > max) {
						max = accum[i][j];
						bestRho = j;
						bestTheta = i;
					}
				}
			}

			if (max > 30) {
				HSctx.fillStyle = 'rgba(255,0,0,1)';
				HSctx.fillRect(bestTheta + border, bestRho, 2, 2);
				HSctx.fillStyle = 'rgba(0,0,0,.1)';

				// now to backproject into drawing space
				bestRho <<= 1; // accumulator is bitshifted
				bestRho -= Std.int(rhoMax); /// accumulator has rhoMax added
				Console.log(bestTheta, bestRho);
				var a = cosTable[bestTheta];
				var b = sinTable[bestTheta];
				var x1 = a * bestRho + 1000 * (-b);
				var y1 = (b * bestRho + 1000 * (a));
				var x2 = a * bestRho - 1000 * (-b);
				var y2 = (b * bestRho - 1000 * (a));
				Console.log(x1, y1, x2, y2);
				ctx.beginPath();
				ctx.strokeStyle = 'rgba(255,0,0,1)';
				ctx.moveTo(x1 + drawingWidth / 2, y1 + drawingHeight / 2);
				ctx.lineTo(x2 + drawingWidth / 2, y2 + drawingHeight / 2);
				ctx.stroke();
				ctx.strokeStyle = 'rgba(0,0,0,1)';
				ctx.closePath();
			}
		}

        var theta = 0.;
        var thetaIndex = 0;
		while (thetaIndex < numAngleCells)
		{
			cosTable[thetaIndex] = Math.cos(theta);
			sinTable[thetaIndex] = Math.sin(theta);
            theta += Math.PI / numAngleCells;
		    thetaIndex++;
		}

		// Implementation with lookup tables.
		function houghAcc(x, y) {
			var rho;
			var thetaIndex = 0;
			x -= Std.int(drawingWidth / 2);
			y -= Std.int(drawingHeight / 2);
			while (thetaIndex < numAngleCells)
			{
				rho = rhoMax + x * cosTable[thetaIndex] + y * sinTable[thetaIndex];
				rho = Std.int(rho) >> 1;
				if (accum[thetaIndex] == null)
					accum[thetaIndex] = [];
				if (accum[thetaIndex][Std.int(rho)] == null) {
					accum[thetaIndex][Std.int(rho)] = 1;
				} else {
					accum[thetaIndex][Std.int(rho)]++;
				}
				drawInHough(rho, thetaIndex);
                thetaIndex++;
			}
			findMaxInHough();
		}

		// Classical implementation.
		function houghAccClassical(x, y) {
			var rho;
			var theta = 0.;
			var thetaIndex = 0;
			x -= Std.int(drawingWidth / 2);
			y -= Std.int(drawingHeight / 2);
			while (thetaIndex < numAngleCells)
			{
				rho = rhoMax + x * Math.cos(theta) + y * Math.sin(theta);
				rho = Std.int(rho) >> 1;
				if (accum[thetaIndex] == null)
					accum[thetaIndex] = [];
				if (accum[thetaIndex][Std.int(rho)] == null) {
					accum[thetaIndex][Std.int(rho)] = 1;
				} else {
					accum[thetaIndex][Std.int(rho)]++;
				}
				drawInHough(rho, thetaIndex);
                theta += Math.PI / numAngleCells;
			    thetaIndex++;
			}
		}

        drawing.addEventListener('mousedown', function() {
			drawingMode = true;
		});
		drawing.addEventListener('mouseup', function() {
			drawingMode = false;
		});
		drawing.addEventListener('mouseout', function() {
			drawingMode = false;
		});
		drawing.addEventListener('mousemove', function(e) {
			if (drawingMode) {
				var rect = drawing.getBoundingClientRect();
				var x = (e.clientX - rect.left) / (rect.right - rect.left) * drawing.width;
				var y = (e.clientY - rect.top) / (rect.bottom - rect.top) * drawing.height;
				ctx.fillStyle = 'rgba(0,0,0,1)';
				ctx.beginPath();
				ctx.fillRect(x - (THICKNESS / 2), y - (THICKNESS / 2), THICKNESS, THICKNESS);
				ctx.closePath();

				houghAcc(Std.int(x), Std.int(y));
			}
		});

        Browser.document.body.appendChild(drawing);
        Browser.document.body.appendChild(houghSp);
	}
    #end
}
