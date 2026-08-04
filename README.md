<div align="center">
  <h1>Estuary</h1>

  <p>
    <img alt="GitHub License" src="https://img.shields.io/github/license/callensm/estuary?color=blue">
    <img alt="GitHub Actions Workflow Status" src="https://img.shields.io/github/actions/workflow/status/callensm/estuary/ci.yaml">
  </p>
</div>

## Configuration

```yaml
# .estuaryrc.yaml

estuary:
  ws_url: <string>
  commitment: processed | confirmed | finalized
  program_id: <string>
  sinks: # Must configure at least one sink type
    - type: stdout
      format: json | pretty
    - type: file
      path: <string> # JSON or JSONL file extension (JSON will be normalized into JSONL)
    - type: webhook
      url: <string>
      timeout_ms: <int>
      headers:
        MY_HEADER: my-header-value
    - type: sqs
      endpoint_url: <string> # Optional
      queue_url: <string>
      region: <string>
    - type: pubsub
      credentials_file: <string> # Path to GCP credentials file
      project_id: <string>
      topic: <string>
    - type: rabbitmq
      # Can provide a fully qualified connection URL string
      url: <string>
      # Optional can provide separate connection options instead
      host: <string>
      port: <string | int>
      username: <string>
      password: <string>
      vhost: <string>
      # Default exchange queue options
      queue: <string>
      # Named exchange with routing key options
      exchange: <string>
      exchange_type: direct | topic | fanout | headers
      routing_key: <string>
```

## License

Copyright 2026 [Matthew Callens](https://github.com/callensm)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

