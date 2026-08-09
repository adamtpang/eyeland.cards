// Unity's runtime doesn't ship the BCL attribute types the C# compiler needs to support
// the `required` keyword (used throughout Eyeland.Duel), even though its compiler accepts
// the syntax. This is the standard, well-known polyfill for that gap -- adding it here
// keeps the actual engine files byte-for-byte identical to the console project, preserving
// their "drops into Assets/Scripts/ unmodified" design intent (see Cards.cs's doc comment).
#if !NET7_0_OR_GREATER
namespace System.Runtime.CompilerServices
{
    // Needed for the `init` accessor (used throughout CardDef and friends), not just `required`.
#if !NET5_0_OR_GREATER
    internal static class IsExternalInit { }
#endif

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Struct | AttributeTargets.Field | AttributeTargets.Property, AllowMultiple = false, Inherited = false)]
    internal sealed class RequiredMemberAttribute : Attribute { }

    [AttributeUsage(AttributeTargets.All, AllowMultiple = true, Inherited = false)]
    internal sealed class CompilerFeatureRequiredAttribute : Attribute
    {
        public CompilerFeatureRequiredAttribute(string featureName) => FeatureName = featureName;
        public string FeatureName { get; }
        public bool IsOptional { get; init; }
    }
}

namespace System.Diagnostics.CodeAnalysis
{
    [AttributeUsage(AttributeTargets.Constructor, AllowMultiple = false, Inherited = false)]
    internal sealed class SetsRequiredMembersAttribute : Attribute { }
}
#endif
