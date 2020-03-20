#> #include <OpenImageIO/imageio.h> <#
#> OIIO_NAMESPACE_USING <#
(bind-rename/pattern "oiio_(([A-Z][a-z]*)+)___" "\\1::")
(bind-rename/pattern "oiio_(([A-Z][a-z]*)+)__" "\\1.")
(bind-rename/pattern "oiio_(([A-Z][a-z]*)+)_" "\\1->")
(bind-file* "oiio-glue.h")

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

;;; auxiliary records

(define-record imageinput pointer)
(define-record imageoutput pointer)
(define-record imagespec pointer)

;;; errors

(define (type-error value expected location)
  (let ((message (format "Bad argument type - not a ~a: ~a" expected value)))
    (condition `(exn location ,location message ,message) '(type))))

(define (oiio-error message location)
  (condition `(exn location ,location message ,message) '(oiio)))

;;; API

(define (imageinput-open filename)
  (let ((imageinput* (ImageInput::open filename)))
    (if imageinput*
        (set-finalizer! (make-imageinput imageinput*) imageinput-destroy)
        (abort (oiio-error (oiio_geterror) 'imageinput-open)))))

(define (imageinput-destroy imageinput)
  (and-let* ((imageinput* (imageinput-pointer imageinput)))
    (ImageInput::destroy imageinput*)
    (imageinput-pointer-set! imageinput #f)))

(define (imageinput-spec imageinput)
  (and-let* ((imageinput* (imageinput-pointer imageinput)))
    (ImageInput->spec imageinput*)))

(define (imageinput-read-image imageinput basetype pixels)
  (when (not (blob? pixels))
    (type-error pixels "blob" 'imageinput-read-image))
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
        (abort (oiio-error (oiio_geterror) 'imageoutput-create)))))

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
  (when (not (blob? pixels))
    (type-error pixels "blob" 'imageinput-write-image))
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
  (oiio_version))
