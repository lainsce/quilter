use gio::{resources_register, Resource};
use glib::{Bytes, Error};

pub(crate) fn init() -> Result<(), Error> {
    let res_bytes = include_bytes!("/home/lains/Documents/Projects/quilter/_build/data/resources.gresource");
    let gbytes = Bytes::from_static(res_bytes.as_ref());
    let resource = Resource::from_data(&gbytes)?;
    resources_register(&resource);
    Ok(())
}
