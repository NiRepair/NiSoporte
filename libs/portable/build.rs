fn main() {
    #[cfg(windows)]
    {
        use std::io::Write;
        let mut res = winres::WindowsResource::new();
        res.set_icon("../../res/icon.ico")
            .set("CompanyName", "NiRepair")
            .set("FileDescription", "NiSoporte - Soporte remoto de NiRepair")
            .set("ProductName", "NiSoporte")
            .set("LegalCopyright", "Copyright RustDesk y sus colaboradores. Adaptación NiRepair.")
            .set("InternalName", "nisoporte")
            .set("OriginalFilename", "NiSoporte.exe")
            .set("Comments", "Basado en RustDesk (AGPL-3.0). Código: https://github.com/NiRepair/NiSoporte")
            .set_language(winapi::um::winnt::MAKELANGID(
                winapi::um::winnt::LANG_ENGLISH,
                winapi::um::winnt::SUBLANG_ENGLISH_US,
            ))
            .set_manifest_file("../../res/manifest.xml");
        match res.compile() {
            Err(e) => {
                write!(std::io::stderr(), "{}", e).unwrap();
                std::process::exit(1);
            }
            Ok(_) => {}
        }
    }
}
