(use oiio)

(define filename "foo.jpg")
(define width 640)
(define height 480)
(define channels 3)
(define pixels (make-blob (* width height channels)))

(define out (imageoutput-create filename))
(define spec (imagespec-create width height channels 'uint8))

(imageoutput-open out filename spec)
(imageoutput-write-image out 'uint8 pixels)
(imageoutput-close out)
