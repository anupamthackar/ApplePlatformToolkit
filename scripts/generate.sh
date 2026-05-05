#!/bin/bash
# Mock generation script using Sourcery
# Assumes Sourcery is installed (e.g. via Homebrew: brew install sourcery)

echo "Generating Mocks and API clients..."

# Ensure we have a Templates directory
mkdir -p .sourcery/Templates
mkdir -p .sourcery/Generated

# Create a sample AutoMockable template if it doesn't exist
cat << 'EOF' > .sourcery/Templates/AutoMockable.stencil
{% for type in types.protocols where type.based.AutoMockable or type|annotated:"AutoMockable" %}
// swiftlint:disable all
class {{ type.name }}Mock: {{ type.name }} {
{% for variable in type.allVariables %}
    var {{ variable.name }}: {{ variable.typeName }} {
        get { return underlying{{ variable.name|upperFirstLetter }} }
        set(value) { underlying{{ variable.name|upperFirstLetter }} = value }
    }
    var underlying{{ variable.name|upperFirstLetter }}: {{ variable.typeName }}!
{% endfor %}

{% for method in type.allMethods %}
    var {{ method.shortName }}CallsCount = 0
    var {{ method.shortName }}Called: Bool {
        return {{ method.shortName }}CallsCount > 0
    }
    {% if method.parameters.count == 1 %}
    var {{ method.shortName }}Received{% for param in method.parameters %}{{ param.name|upperFirstLetter }}: {{ param.typeName.unwrappedTypeName }}?{% endfor %}
    var {{ method.shortName }}ReceivedInvocations: [{% for param in method.parameters %}{{ param.typeName.unwrappedTypeName }}{% endfor %}] = []
    {% elif not method.parameters.isEmpty %}
    var {{ method.shortName }}ReceivedArguments: ({% for param in method.parameters %}{{ param.name }}: {{ param.typeName.unwrappedTypeName }}{% if not forloop.last %}, {% endif %}{% endfor %})?
    var {{ method.shortName }}ReceivedInvocations: [({% for param in method.parameters %}{{ param.name }}: {{ param.typeName.unwrappedTypeName }}{% if not forloop.last %}, {% endif %}{% endfor %})] = []
    {% endif %}
    {% if not method.returnTypeName.isVoid %}
    var {{ method.shortName }}ReturnValue: {{ method.returnTypeName }}!
    {% endif %}
    {% if method.throws %}
    var {{ method.shortName }}ThrowableError: Error?
    {% endif %}

{% if method.isInitializer %}
    required {{ method.name }} {
        {{ method.shortName }}CallsCount += 1
        {% if method.parameters.count == 1 %}
        {% for param in method.parameters %}
        {{ method.shortName }}Received{{ param.name|upperFirstLetter }} = {{ param.name }}
        {{ method.shortName }}ReceivedInvocations.append({{ param.name }})
        {% endfor %}
        {% elif not method.parameters.isEmpty %}
        {{ method.shortName }}ReceivedArguments = ({% for param in method.parameters %}{{ param.name }}: {{ param.name }}{% if not forloop.last %}, {% endif %}{% endfor %})
        {{ method.shortName }}ReceivedInvocations.append(({% for param in method.parameters %}{{ param.name }}: {{ param.name }}{% if not forloop.last %}, {% endif %}{% endfor %}))
        {% endif %}
    }
{% else %}
    func {{ method.name }}{% if method.throws %} throws{% endif %}{% if not method.returnTypeName.isVoid %} -> {{ method.returnTypeName }}{% endif %} {
        {{ method.shortName }}CallsCount += 1
        {% if method.parameters.count == 1 %}
        {% for param in method.parameters %}
        {{ method.shortName }}Received{{ param.name|upperFirstLetter }} = {{ param.name }}
        {{ method.shortName }}ReceivedInvocations.append({{ param.name }})
        {% endfor %}
        {% elif not method.parameters.isEmpty %}
        {{ method.shortName }}ReceivedArguments = ({% for param in method.parameters %}{{ param.name }}: {{ param.name }}{% if not forloop.last %}, {% endif %}{% endfor %})
        {{ method.shortName }}ReceivedInvocations.append(({% for param in method.parameters %}{{ param.name }}: {{ param.name }}{% if not forloop.last %}, {% endif %}{% endfor %}))
        {% endif %}
        {% if method.throws %}
        if let error = {{ method.shortName }}ThrowableError {
            throw error
        }
        {% endif %}
        {% if not method.returnTypeName.isVoid %}
        return {{ method.shortName }}ReturnValue
        {% endif %}
    }
{% endif %}
{% endfor %}
}
// swiftlint:enable all
{% endfor %}
EOF

# Run sourcery
# sourcery --sources ./Sources --templates ./.sourcery/Templates --output ./.sourcery/Generated

echo "Code generation templates initialized successfully."
