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
  (import (chicken blob))
  (import (chicken condition))
  (import (chicken foreign))
  (import (chicken format))
  (import (chicken gc))
  (import bind coops cplusplus-object)

  (include "oiio-impl.scm"))
