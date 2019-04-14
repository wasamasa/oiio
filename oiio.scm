(module oiio
  (imageinput-open imageinput-destroy
   imageinput-spec imageinput-read-image imageinput-close
   imageoutput-create imageoutput-destroy
   imageoutput-open imageoutput-write-image imageoutput-close
   imagespec-create imagespec-destroy
   imagespec-width imagespec-height imagespec-nchannels
   openimageio-version)

  (import scheme)
  (import (chicken base))
  (import (chicken condition))
  (import (chicken foreign))
  (import (chicken gc))

  (include "oiio-impl.scm"))
