package vision.algorithms;

import haxe.ds.Vector;
import vision.ds.hough.HoughAccumulator;
import vision.ds.hough.HoughSpace;
import vision.ds.Point2D;
import vision.ds.Line2D;
import vision.ds.Color;
import vision.ds.Ray2D;
import vision.ds.Image;

using vision.tools.MathTools;

import vision.tools.MathTools.*;

/**
	A Hough Transform implementation by [Shahar Marcus](https://www.github.com/ShaharMS).

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
		final rhoMax = Math.sqrt(image.width * image.width + image.height * image.height);
		final accumulator:HoughAccumulator = new HoughAccumulator(Std.int(rhoMax));
		final houghSpace = new Image(181, Std.int(rhoMax), Color.WHITE);
		for (x in 0...image.width) {
			for (y in 0...image.height) {
				if (Math.abs(image.getPixel(x, y).red) == 255) {
					var rho:Float;
					var theta = 0.;
					var thetaIndex = 0;
					while (thetaIndex < 180) {
						rho = x * Math.cos(theta) + y * Math.sin(theta);
						accumulator.incrementCell(rho, thetaIndex);
						houghSpace.paintPixel(thetaIndex, Std.int(rho), Color.fromRGBAFloat(0, 0, 0, 0.01));
						theta += Math.PI / 360;
						thetaIndex++;
					}
				}
			}
		}
		return {accumulator: accumulator, image: houghSpace};
	}

	public static function detectMaximas(space:HoughSpace, ?threshold:Int = 30):HoughSpace {
		space.maximums = space.accumulator.getMaximas(threshold);
		return space;
	}

	public static function getRays(space:HoughSpace):HoughSpace {
		final houghHeight = cast (Math.sqrt(2) * Math.max(space.image.height, space.image.width)) / 2;
		final centerX = space.image.width / 2;
		final centerY = space.image.height / 2;
		space.rays = [];
		for (max in space.maximums) {
			var theta = degreesToRadians(max.y);
			var r = max.x;

			final thetaSin = Math.sin(theta);
			final thetaCos = Math.cos(theta);

			if (theta < Math.PI * 0.25 || theta > Math.PI * 0.75) {
				var x1 = 0, y1 = 0;
				var x2 = 0, y2 = space.image.height - 1;

				x1 = cast((((r - houghHeight) - ((y1 - centerY) * thetaSin)) / thetaCos) + centerX);
				x2 = cast((((r - houghHeight) - ((y2 - centerY) * thetaSin)) / thetaCos) + centerX);

				space.rays.push(Ray2D.from2Points({x: x1, y: y1}, {x: x2, y: y2}));
			} else {
				var x1 = 0, y1 = 0;
				var x2 = space.image.width - 1, y2 = 0;

				y1 = cast((((r - houghHeight) - ((x1 - centerX) * thetaCos)) / thetaSin) + centerY);
				y2 = cast((((r - houghHeight) - ((x2 - centerX) * thetaCos)) / thetaSin) + centerY);

				space.rays.push(Ray2D.from2Points({x: x1, y: y1}, {x: x2, y: y2}));
			}
		}
		return space;
	}
}
