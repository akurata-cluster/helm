{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Injects a default securityContext into a list of containers.
*/}}
{{- define "app.secureContainers" -}}
{{- $modifiedContainers := list -}}

{{- range $origContainer := . -}}
  {{- /* Deep copy to prevent mutating global scope */ -}}
  {{- $container := deepCopy $origContainer -}}
  
  {{- /* Define defaults */ -}}
  {{- $reqSecContext := dict 
        "allowPrivilegeEscalation" false 
        "runAsNonRoot" true 
        "capabilities" (dict 
            "drop" (list "ALL")
        ) 
  -}}
  
  {{- /* Extract user context and merge */ -}}
  {{- $userSecContext := deepCopy (default dict $container.securityContext) -}}
  {{- $mergedSecContext := mergeOverwrite $userSecContext $reqSecContext -}}
  
  {{- /* Apply merged context and append to our new list */ -}}
  {{- $_ := set $container "securityContext" $mergedSecContext -}}
  {{- $modifiedContainers = append $modifiedContainers $container -}}
{{- end -}}

{{- /* Output the entire modified list as YAML */ -}}
{{- toYaml $modifiedContainers -}}
{{- end -}}