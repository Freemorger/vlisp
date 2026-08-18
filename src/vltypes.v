module main

enum VlType {
    int
    float
	string
	astn
}

fn av_to_atype(v AValue) ?VlType {
    return match v {
        int { .int }
        f64 { .float }
		string { .string }
        else { return none }
    }
}

fn higher_common(a AValue, b AValue) ?VlType {
    ta := av_to_atype(a) or { return none };
    tb := av_to_atype(b) or { return none };

	if ta == .float || tb == .float {
        return .float
    }

    return .int
}

/// Converts into specified vltype
fn av_into_nt(av AValue, vlt VlType) !AValue {
	match av {
		int {
			match vlt {
				.int    {return av}
				.float  {return f64(av)}
				.string {return '${av}'}
				.astn   {return error('Converting to astnode is not possible.')}
			}
		}
		f64 {
			match vlt {
				.int    {return int(av)}
				.float  {return av}
				.string {return '${av}'}
				.astn   {return error('Converting to astnode is not possible.')}
			}
		}
		string {
			match vlt {
				.int    {return av.int()}
				.float  {return av.f64()}
				.string {return '${av}'}
				.astn   {return error('Converting to astnode is not possible.')}
			}
		}
		else {
			error("Can't cast ${av} into ${vlt}")
		}
	}
}
