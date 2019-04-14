(import scheme)
(import (chicken base))
(import (chicken blob))
(import (chicken locative))
(import (prefix epoxy gl:))
(import (prefix glfw3 glfw:))
(import (prefix gl-utils glu:))
(import (srfi 4))
(import (srfi 18))
(import oiio)

(define width 500)
(define height 500)

(define mesh
  (glu:make-mesh
   vertices: '(attributes: ((position float: 2)
                            (texcoord float: 2))
               initial-elements: ((position -0.5 -0.5
                                            -0.5  0.5
                                             0.5  0.5

                                            -0.5 -0.5
                                             0.5 -0.5
                                             0.5  0.5)
                                  (texcoord 0.0 1.0
                                            0.0 0.0
                                            1.0 0.0
                                            0.0 1.0
                                            1.0 1.0
                                            1.0 0.0)))))

(define vertex-shader-source
  "#version 150 core
   in vec2 position;
   in vec2 texcoord;
   out vec2 Texcoord;

   void main() {
       Texcoord = texcoord;
       gl_Position = vec4(position, 0.0, 1.0);
   }")

(define fragment-shader-source
  "#version 150 core
   in vec2 Texcoord;
   out vec4 outColor;
   uniform sampler2D tex;

   void main() {
       outColor = texture(tex, Texcoord);
   }")

(define (load-image path)
  (let* ((in (imageinput-open path))
         (spec (imageinput-spec in))
         (width (imagespec-width spec))
         (height (imagespec-height spec))
         (channels (imagespec-nchannels spec))
         (size (* width height channels))
         (pixels (make-blob size)))
    (imageinput-read-image in 'uint8 pixels)
    (imageinput-close in)
    (values width height channels pixels)))

(define-values (image-width image-height image-channels image-pixels)
  (load-image "texture.jpg"))

(define image-format
  (case image-channels
    ((3) gl:+rgb+)
    ((4) gl:+rgba+)))

(define image (make-locative image-pixels))

(define (main)
  (glfw:with-window (width height "Test"
                           resizable: #f
                           context-version-major: 3
                           context-version-minor: 2
                           opengl-forward-compat: #t
                           opengl-profile: glfw:+opengl-core-profile+)
    (glfw:make-context-current (glfw:window))
    (let* ((texture (glu:gen-texture))
           (vertex-shader (glu:make-shader gl:+vertex-shader+ vertex-shader-source))
           (fragment-shader (glu:make-shader gl:+fragment-shader+ fragment-shader-source))
           (program (glu:make-program (list vertex-shader fragment-shader))))
      (gl:use-program program)
      (glu:mesh-make-vao! mesh `((position . ,(gl:get-attrib-location
                                               program "position"))
                                 (texcoord . ,(gl:get-attrib-location
                                               program "texcoord"))))
      (gl:bind-vertex-array (glu:mesh-vao mesh))
      (gl:bind-texture gl:+texture-2d+ texture)
      (gl:pixel-storei gl:+unpack-alignment+ 1)
      (gl:tex-image-2d gl:+texture-2d+ 0 gl:+rgb+ image-width image-height 0
                       image-format gl:+unsigned-byte+ image)
      (gl:tex-parameteri gl:+texture-2d+ gl:+texture-wrap-s+ gl:+clamp-to-edge+)
      (gl:tex-parameteri gl:+texture-2d+ gl:+texture-wrap-t+ gl:+clamp-to-edge+)
      (gl:tex-parameteri gl:+texture-2d+ gl:+texture-min-filter+ gl:+linear+)
      (gl:tex-parameteri gl:+texture-2d+ gl:+texture-mag-filter+ gl:+linear+)
      (let loop ()
        (glfw:poll-events)
        (gl:clear-color 0.0 0.0 0.0 1.0)
        (gl:clear gl:+color-buffer-bit+)
        (gl:draw-arrays gl:+triangles+ 0 (glu:mesh-n-vertices mesh))
        (glfw:swap-buffers (glfw:window))
        (when (not (glfw:window-should-close (glfw:window)))
          (thread-sleep! 0.01)
          (loop)))
      (glu:delete-texture texture)
      (gl:delete-program program)
      (gl:delete-shader vertex-shader)
      (gl:delete-shader fragment-shader))))

(main)
