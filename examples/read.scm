(import scheme)
(import (chicken base))
(import (chicken blob))
(import oiio)

(define filename "foo.jpg")
(define in (imageinput-open filename))
(define spec (imageinput-spec in))

(define width (imagespec-width spec))
(define height (imagespec-height spec))
(define channels (imagespec-nchannels spec))
(define pixels (make-blob (* width height channels)))

(imageinput-read-image in 'uint8 pixels)
(imageinput-close in)

(display pixels)
