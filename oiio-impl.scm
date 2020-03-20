#> #include "oiio.h" <#

;;; enums

(define TypeDesc::UINT8 (foreign-value "TypeDesc::UINT8" int))
(define TypeDesc::INT8 (foreign-value "TypeDesc::INT8" int))
(define TypeDesc::UINT16 (foreign-value "TypeDesc::UINT16" int))
(define TypeDesc::INT16 (foreign-value "TypeDesc::INT16" int))
(define TypeDesc::UINT32 (foreign-value "TypeDesc::UINT32" int))
(define TypeDesc::INT32 (foreign-value "TypeDesc::INT32" int))
(define TypeDesc::HALF (foreign-value "TypeDesc::HALF" int))
(define TypeDesc::FLOAT (foreign-value "TypeDesc::FLOAT" int))
(define TypeDesc::DOUBLE (foreign-value "TypeDesc::DOUBLE" int))

(define (typedesc-basetype->int flag)
  (case flag
    ((uint8) TypeDesc::UINT8)
    ((int8) TypeDesc::INT8)
    ((uint16) TypeDesc::UINT16)
    ((int16) TypeDesc::INT16)
    ((uint32) TypeDesc::UINT32)
    ((int32) TypeDesc::INT32)
    ((half) TypeDesc::HALF)
    ((float) TypeDesc::FLOAT)
    ((double) TypeDesc::DOUBLE)))

;;; typedefs

(define-foreign-type nullable-ImageInput* (c-pointer (struct "ImageInput")))
(define-foreign-type ImageInput* (nonnull-c-pointer (struct "ImageInput")))
(define-foreign-type nullable-ImageOutput* (c-pointer (struct "ImageOutput")))
(define-foreign-type ImageOutput* (nonnull-c-pointer (struct "ImageOutput")))
(define-foreign-type ImageSpec& (instance-ref "ImageSpec" 'imagespec))
(define-foreign-type ImageSpec (instance "ImageSpec" 'imagespec))

;;; auxiliary records

(define-record imageinput pointer)
(define-record imageoutput pointer)
(define-record imagespec pointer)

;;; class helpers

(define (make type _slot pointer)
  (case type
    ((imagespec) (make-imagespec pointer))
    (else (error "Unknown C++ type"))))

(define (slot-ref thing _slot)
  (cond
   ((imagespec? thing) (imagespec-pointer thing))
   (else (error "Unknown C++ type"))))

;;; foreign functions

(define openimageio_version (foreign-lambda int "openimageio_version"))
(define geterror (foreign-lambda c-string* "oiio_geterror"))
(define ImageSpec::create (foreign-lambda ImageSpec "oiio_ImageSpec_create" int int int int))
(define ImageSpec::destroy (foreign-lambda void "oiio_ImageSpec_destroy" ImageSpec))
(define ImageSpec.width (foreign-lambda int "oiio_ImageSpec_width" ImageSpec&))
(define ImageSpec.height (foreign-lambda int "oiio_ImageSpec_height" ImageSpec&))
(define ImageSpec.nchannels (foreign-lambda int "oiio_ImageSpec_nchannels" ImageSpec&))

(define ImageInput::open (foreign-lambda nullable-ImageInput* "oiio_ImageInput_open" c-string))
(define ImageInput::destroy (foreign-lambda void "oiio_ImageInput_destroy" ImageInput*))
(define ImageInput->spec (foreign-lambda ImageSpec& "oiio_ImageInput_spec" ImageInput*))
(define ImageInput->geterror (foreign-lambda c-string* "oiio_ImageInput_geterror" ImageInput*))
(define ImageInput->read_image (foreign-lambda bool "oiio_ImageInput_read_image" ImageInput* int blob))
(define ImageInput->close (foreign-lambda bool "oiio_ImageInput_close" ImageInput*))

(define ImageOutput::create (foreign-lambda nullable-ImageOutput* "oiio_ImageOutput_create" nonnull-c-string))
(define ImageOutput::destroy (foreign-lambda void "oiio_ImageOutput_destroy" ImageOutput*))
(define ImageOutput->geterror (foreign-lambda c-string* "oiio_ImageOutput_geterror" ImageOutput*))
(define ImageOutput->open (foreign-lambda bool "oiio_ImageOutput_open" ImageOutput* c-string ImageSpec&))
(define ImageOutput->write_image (foreign-lambda bool "oiio_ImageOutput_write_image" ImageOutput* int blob))
(define ImageOutput->close (foreign-lambda bool "oiio_ImageOutput_close" ImageOutput*))

;;; errors

(define (type-error message location)
  (condition `(exn location ,location message ,message) '(type)))

(define (oiio-error message location)
  (condition `(exn location ,location message ,message) '(oiio)))

;;; API

(define (imageinput-open filename)
  (let ((imageinput* (ImageInput::open filename)))
    (if imageinput*
        (set-finalizer! (make-imageinput imageinput*) imageinput-destroy)
        (abort (oiio-error (geterror) 'imageinput-open)))))

(define (imageinput-destroy imageinput)
  (and-let* ((imageinput* (imageinput-pointer imageinput)))
    (ImageInput::destroy imageinput*)
    (imageinput-pointer-set! imageinput #f)))

(define (imageinput-spec imageinput)
  (and-let* ((imageinput* (imageinput-pointer imageinput)))
    (ImageInput->spec imageinput*)))

(define (imageinput-read-image imageinput basetype pixels)
  (and-let* ((imageinput* (imageinput-pointer imageinput)))
    (let ((flag (typedesc-basetype->int basetype)))
      (when (not (ImageInput->read_image imageinput* flag pixels))
        (abort (oiio-error (ImageInput->geterror imageinput*)
                           'imageinput-read-image))))))

(define (imageinput-close imageinput)
  (and-let* ((imageinput* (imageinput-pointer imageinput)))
    (when (not (ImageInput->close imageinput*))
      (abort (oiio-error (ImageInput->geterror imageinput*)
                         'imageinput-close)))))

(define (imageoutput-create filename)
  (let ((imageoutput* (ImageOutput::create filename)))
    (if imageoutput*
        (set-finalizer! (make-imageoutput imageoutput*) imageoutput-destroy)
        (abort (oiio-error (geterror) 'imageoutput-create)))))

(define (imageoutput-destroy imageoutput)
  (and-let* ((imageoutput* (imageoutput-pointer imageoutput)))
    (ImageOutput::destroy imageoutput*)
    (imageoutput-pointer-set! imageoutput #f)))

(define (imageoutput-open imageoutput filename imagespec)
  (and-let* ((imageoutput* (imageoutput-pointer imageoutput))
             ((imagespec-pointer imagespec)))
    (when (not (ImageOutput->open imageoutput* filename imagespec))
      (abort (oiio-error (ImageOutput->geterror imageoutput*)
                         'imageoutput-open)))))

(define (imageoutput-write-image imageoutput basetype pixels)
  (and-let* ((imageoutput* (imageoutput-pointer imageoutput)))
    (let ((flag (typedesc-basetype->int basetype)))
      (when (not (ImageOutput->write_image imageoutput* flag pixels))
        (abort (oiio-error (ImageOutput->geterror imageoutput*)
                           'imageoutput-write-image))))))

(define (imageoutput-close imageoutput)
  (and-let* ((imageoutput* (imageoutput-pointer imageoutput)))
    (when (not (ImageOutput->close imageoutput*))
      (abort (oiio-error (ImageOutput->geterror imageoutput*)
                         'imageoutput-close)))))

(define (imagespec-create width height channels basetype)
  (let ((flag (typedesc-basetype->int basetype)))
    (set-finalizer! (ImageSpec::create width height channels flag)
                    imagespec-destroy)))

(define (imagespec-destroy imagespec)
  (when (imagespec-pointer imagespec)
    (ImageSpec::destroy imagespec)
    (imagespec-pointer-set! imagespec #f)))

(define (imagespec-width imagespec)
  (when (imagespec-pointer imagespec)
    (ImageSpec.width imagespec)))

(define (imagespec-height imagespec)
  (when (imagespec-pointer imagespec)
    (ImageSpec.height imagespec)))

(define (imagespec-nchannels imagespec)
  (when (imagespec-pointer imagespec)
    (ImageSpec.nchannels imagespec)))

(define (openimageio-version)
  (openimageio_version))
