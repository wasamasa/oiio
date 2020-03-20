int oiio_version() {
    return openimageio_version();
}

char* oiio_geterror() {
    return strdup(geterror().c_str());
}

ImageSpec* oiio_ImageSpec___create(int width, int height, int channels, int type) {
    return new ImageSpec(width, height, channels, TypeDesc::BASETYPE(type));
}

void oiio_ImageSpec___destroy(ImageSpec *spec) {
    delete spec;
}

int oiio_ImageSpec__width(ImageSpec &spec) {
    return spec.width;
}

int oiio_ImageSpec__height(ImageSpec &spec) {
    return spec.height;
}

int oiio_ImageSpec__nchannels(ImageSpec &spec) {
    return spec.nchannels;
}

ImageInput* oiio_ImageInput___open(char *path) {
    auto in = ImageInput::open(path);
    return in ? in.release() : NULL;
}

void oiio_ImageInput___destroy(ImageInput *in) {
    delete in;
}

ImageSpec& oiio_ImageInput_spec(ImageInput *in) {
    return (ImageSpec&) in->spec();
}

char* oiio_ImageInput_geterror(ImageInput *in) {
    return strdup(in->geterror().c_str());
}

bool oiio_ImageInput_read_image(ImageInput *in, int type, C_word blob) {
    return in->read_image(TypeDesc::BASETYPE(type), C_c_bytevector(blob));
}

bool oiio_ImageInput_close(ImageInput *in) {
    return in->close();
}

ImageOutput* oiio_ImageOutput___create(char *path) {
    auto out = ImageOutput::create(path);
    return out ? out.release() : NULL;
}

void oiio_ImageOutput___destroy(ImageOutput *out) {
    delete out;
}

char* oiio_ImageOutput_geterror(ImageOutput *out) {
    return strdup(out->geterror().c_str());
}

bool oiio_ImageOutput_open(ImageOutput *out, char *filename, ImageSpec &spec) {
    return out->open(filename, spec);
}

bool oiio_ImageOutput_write_image(ImageOutput *out, int type, C_word blob) {
    return out->write_image(TypeDesc::BASETYPE(type), C_c_bytevector(blob));
}

bool oiio_ImageOutput_close(ImageOutput *out) {
    return out->close();
}
