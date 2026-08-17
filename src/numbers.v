module main

enum NumericType {
    int
    float
}

fn numeric_type(v AValue) ?NumericType {
    return match v {
        int { .int }
        f64 { .float }
        else { return none }
    }
}

fn higher_common(a AValue, b AValue) ?NumericType {
    ta := numeric_type(a) or { return none };
    tb := numeric_type(b) or { return none };

    if ta == .float || tb == .float {
        return .float
    }

    return .int
}

/// Converts by specified numerictype
fn av_into_nt(av AValue, nt NumericType) !AValue {
	match av {
		int {
			match nt {
				.int {return av}
				.float {return f64(av)}
			}
		}
		f64 {
			match nt {
				.int {return int(av)}
				.float {return av}
			}
		}
		string {
			match nt {
				.int {return av.int()}
				.float {return av.f64()}
			}
		}
		else {
			error("Can't cast ${av} into ${nt}")
		}
	}
}
