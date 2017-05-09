(module oiio
  (imageinput-open imageinput-destroy
   imageinput-spec imageinput-read-image imageinput-close
   imageoutput-create imageoutput-destroy
   imageoutput-open imageoutput-write-image imageoutput-close
   imagespec-create imagespec-destroy
   imagespec-width imagespec-height imagespec-nchannels
   openimageio-version)

(import chicken scheme foreign)
(use lolevel coops)

;;; headers

#>
#include <OpenImageIO/imageio.h>
OIIO_NAMESPACE_USING
<#

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
(define-foreign-type ImageSpec& (instance-ref "ImageSpec" <imagespec>))
(define-foreign-type ImageSpec (instance "ImageSpec" <imagespec>))

;;; auxiliary records

(define-record imageinput pointer)
(define-record imageoutput pointer)

;;; class helpers

(define-class <imagespec> ()
  ((this #f)))

;;; foreign functions

;; TODO: use const where appropriate

(define openimageio_version (foreign-lambda int "openimageio_version"))
(define geterror (foreign-lambda* c-string* () "C_return(strdup(geterror().c_str()));"))
(define ImageSpec::create (foreign-lambda* ImageSpec ((int width) (int height) (int channels) (int type)) "C_return(new ImageSpec(width, height, channels, TypeDesc::BASETYPE(type)));"))
(define ImageSpec::destroy (foreign-lambda* void ((ImageSpec imagespec)) "delete imagespec;"))
(define ImageInput::open (foreign-lambda nullable-ImageInput* "ImageInput::open" c-string))
(define ImageInput::destroy (foreign-lambda void "ImageInput::destroy" ImageInput*))
(define ImageInput->spec (foreign-lambda* ImageSpec& ((ImageInput* in)) "C_return(in->spec());"))
(define ImageInput->geterror (foreign-lambda* c-string* ((ImageInput* in)) "C_return(strdup(in->geterror().c_str()));"))
(define ImageInput->read_image (foreign-lambda* bool ((ImageInput* in) (int type) (blob pixels)) "C_return(in->read_image(TypeDesc::BASETYPE(type), pixels));"))
(define ImageInput->close (foreign-lambda* bool ((ImageInput* in)) "C_return(in->close());"))
(define ImageOutput::create (foreign-lambda nullable-ImageOutput* "ImageOutput::create" nonnull-c-string))
(define ImageOutput::destroy (foreign-lambda void "ImageOutput::destroy" ImageOutput*))
(define ImageOutput->geterror (foreign-lambda* c-string* ((ImageOutput* out)) "C_return(strdup(out->geterror().c_str()));"))
(define ImageOutput->open (foreign-lambda* bool ((ImageOutput* out) (nonnull-c-string filename) (ImageSpec& spec)) "C_return(out->open(filename, spec));"))
(define ImageOutput->write_image (foreign-lambda* bool ((ImageOutput* out) (int type) (blob pixels)) "C_return(out->write_image(TypeDesc::BASETYPE(type), pixels));"))
(define ImageOutput->close (foreign-lambda* bool ((ImageOutput* out)) "C_return(out->close());"))
(define ImageSpec.width (foreign-lambda* int ((ImageSpec& spec)) "C_return(spec.width);"))
(define ImageSpec.height (foreign-lambda* int ((ImageSpec& spec)) "C_return(spec.height);"))
(define ImageSpec.nchannels (foreign-lambda* int ((ImageSpec& spec)) "C_return(spec.nchannels);"))

;;; errors

(define (define-error location message #!rest condition)
  (let ((base (make-property-condition 'exn 'location location 'message message))
        (extra (apply make-property-condition condition)))
    (make-composite-condition base extra)))

(define (type-error message location)
  (define-error location message 'type))

(define (oiio-error message location)
  (define-error location message 'oiio))

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
             ((slot-ref imagespec 'this)))
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
  (when (slot-ref imagespec 'this)
    (ImageSpec::destroy imagespec)
    (set! (slot-ref imagespec 'this) #f)))

(define (imagespec-width imagespec)
  (when (slot-ref imagespec 'this)
    (ImageSpec.width imagespec)))

(define (imagespec-height imagespec)
  (when (slot-ref imagespec 'this)
    (ImageSpec.height imagespec)))

(define (imagespec-nchannels imagespec)
  (when (slot-ref imagespec 'this)
    (ImageSpec.nchannels imagespec)))

(define (openimageio-version)
  (openimageio_version))

)
