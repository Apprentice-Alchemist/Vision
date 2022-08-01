package vision.algorithms;

import haxe.ds.BalancedTree;
import vision.ds.hough.HoughAccumulator;
import haxe.Timer;
import vision.ds.hough.HoughSpace;
import vision.ds.Matrix;
import vision.ds.Point2D;
import vision.ds.Color;
import haxe.ds.Vector;
import vision.ds.Ray2D;
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
class Hough {
	/**
		Uses the Hough Transform to generate an accumulator based on the
		image provided.

		@param image The image to be transformed.

		@return A `HoughSpace` object, containing the accumulator and an image representation of the accumulator.
	**/
	public static function toHoughSpace(image:Image):HoughSpace {
		var accum:HoughAccumulator = new HoughAccumulator();
		var rhoMax = Math.sqrt(image.width * image.width + image.height * image.height);
		var houghSpace = new Image(361, Std.int(rhoMax), Color.WHITE);
		for (i in 0...image.width) {
			for (j in 0...image.height) {
				if (Math.abs(image.getPixel(i, j).red) == 255) {
					var rho:Float;
					var theta = 0.;
					var thetaIndex = 0;
					var x = i - Std.int(image.width / 2);
					var y = j - Std.int(image.height / 2);
					while (thetaIndex < 360) {
						rho = rhoMax + x * Math.cos(theta) + y * Math.sin(theta);
						rho /= 2;
						if (accum[thetaIndex] == null) {
							accum[thetaIndex] = [];
						} else if (accum[thetaIndex][Std.int(rho)] == null) {
							accum[thetaIndex][Std.int(rho)] = 0;
						} else {
							accum[thetaIndex][Std.int(rho)] += 1;
						}
						houghSpace.setPixel(thetaIndex, Std.int(rho), houghSpace.getPixel(thetaIndex, Std.int(rho)).darken(0.02));
						
						theta += Math.PI / 360;
						thetaIndex++;
					}
				}
			}
		}
		return {accumulator: accum, image: houghSpace};
	}

}
	