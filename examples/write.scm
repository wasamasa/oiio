(import scheme)
(import (chicken base))
(import (srfi 4))
(import oiio)

(define filename "foo.jpg")
(define width 640)
(define height 480)
(define channels 3)
(define pixels (u8vector->blob (make-u8vector (* width height channels) 0)))

(define out (imageoutput-create filename))
(define spec (imagespec-create width height channels 'uint8))

(imageoutput-open out filename spec)
(imageoutput-write-image out 'uint8 pixels)
(imageoutput-close out)
