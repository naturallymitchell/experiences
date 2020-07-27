// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

use {
    anyhow::Error, fuchsia_async as fasync, fuchsia_component::server::ServiceFs,
    fuchsia_syslog as syslog, futures::prelude::*,
};

mod profiles_service;

fn main() -> Result<(), Error> {
    syslog::init_with_tags(&["terminal-settings-agent"]).expect("Can't init logger");
    let mut executor = fasync::Executor::new()?;
    let mut fs = ServiceFs::new();
    let mut public = fs.dir("svc");

    public.add_fidl_service(move |stream| {
        fasync::Task::spawn(
            profiles_service::run_fidl_server(stream)
                .unwrap_or_else(|e| panic!("Error while serving profiles service: {}", e)),
        ).detach()
    });

    fs.take_and_serve_directory_handle()?;
    let () = executor.run_singlethreaded(fs.collect());

    Ok(())
}
